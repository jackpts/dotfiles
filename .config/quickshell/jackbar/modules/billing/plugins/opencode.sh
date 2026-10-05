#!/usr/bin/env bash
# opencode.sh — OpenCode usage plugin for jackbar billing.
# argv[1] is the provider object from providers.json.
# Console service keys (oc_sk_…) hit usage export + budgets.
# Zen keys (sk-…) cannot read Console billing; we probe Zen and read local opencode.db.
set -euo pipefail
export LC_ALL=C

PROVIDER_JSON="${1:-{}}"
ID=$(printf '%s' "$PROVIDER_JSON" | jq -r '.id // "opencode"' 2>/dev/null || printf 'opencode')
DAILY_LIMIT=$(printf '%s' "$PROVIDER_JSON" | jq -r '.daily_limit_usd // empty' 2>/dev/null || true)
DASHBOARD_URL=$(printf '%s' "$PROVIDER_JSON" | jq -r '.dashboard_url // empty' 2>/dev/null || true)
ORG_ID=$(printf '%s' "$DASHBOARD_URL" | grep -oE 'wrk_[A-Z0-9]+' | head -1 || true)
CONSOLE_URL="${OPENCODE_CONSOLE_URL:-https://opencode.ai/console}"
OPENCODE_DB="${OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}"

emit() {
    jq -n \
        --arg id "$ID" \
        --argjson ok "$1" \
        --argjson remaining "$2" \
        --argjson spent "$3" \
        --argjson tokens "$4" \
        --argjson bytes "$5" \
        --argjson limits "$6" \
        --arg err "$7" \
        '{
            id: $id,
            ok: $ok,
            remaining_usd: $remaining,
            spent_today_usd: $spent,
            tokens_today: $tokens,
            bytes_est: $bytes,
            limits: $limits,
            error: (if $err == "" then null else $err end)
        }'
}

error_out() {
    emit false null null null null '[]' "$1"
    exit 0
}

add_spent() {
    local period="$1" used="$2" tok="${3:-null}"
    case "$used" in
        ""|null) return 0 ;;
    esac
    if jq -e --arg p "$period" 'any(.[]?; .period == $p)' <<<"$limits" >/dev/null 2>&1; then
        return 0
    fi
    [ -n "$tok" ] || tok="null"
    limits=$(jq -c --arg p "$period" --argjson used "$used" --argjson tok "$tok" '
        . + [{
            period: $p,
            used: $used,
            limit: null,
            percent: null,
            tokens: (if $tok == null then null else $tok end),
            spent: true
        }]
    ' <<<"$limits")
}

classify_key() {
    case "$1" in
        oc_sk_*) printf 'console' ;;
        *) printf 'zen' ;;
    esac
}

# Prepaid wallet lives on GET /api/billing/status (session cookie + x-org-id).
# Service account keys still 403 that route; reuse the signed-in Zen/Firefox
# __Host-console_session cookie the same way Cursor reads its local IDE session.
console_session_cookie() {
    if [ -n "${OPENCODE_CONSOLE_SESSION:-}" ]; then
        printf '%s' "$OPENCODE_CONSOLE_SESSION"
        return
    fi
    python3 - <<'PY'
import glob, os, shutil, sqlite3, tempfile

patterns = [
    os.path.expanduser("~/.zen/*/cookies.sqlite"),
    os.path.expanduser("~/.mozilla/firefox/*/cookies.sqlite"),
    os.path.expanduser("~/.librewolf/*/cookies.sqlite"),
]
best = None
for pattern in patterns:
    for db in glob.glob(pattern):
        fd, tmp = tempfile.mkstemp(suffix=".sqlite")
        os.close(fd)
        extras = []
        try:
            shutil.copy2(db, tmp)
            for ext in ("-wal", "-shm"):
                src = db + ext
                if os.path.exists(src):
                    shutil.copy2(src, tmp + ext)
                    extras.append(tmp + ext)
            con = sqlite3.connect(tmp, timeout=2)
            rows = con.execute(
                """
                SELECT value, expiry FROM moz_cookies
                WHERE name = '__Host-console_session'
                  AND host IN ('opencode.ai', '.opencode.ai')
                """
            ).fetchall()
            con.close()
            for value, expiry in rows:
                if not value:
                    continue
                exp = expiry or 0
                if best is None or exp > best[0]:
                    best = (exp, value)
        except Exception:
            pass
        finally:
            for path in [tmp, *extras]:
                try:
                    os.remove(path)
                except OSError:
                    pass
if best:
    print(best[1], end="")
PY
}

short_err() {
    local code="$1" body="$2"
    if [ "$code" = "403" ]; then
        printf 'forbidden (service key needs All / usage+budgets permission)'
        return
    fi
    if [ "$code" = "401" ]; then
        printf 'unauthorized'
        return
    fi
    printf 'HTTP %s' "$code"
}

console_key=""
zen_key=""
for k in "${OPENCODE_CONSOLE_KEY:-}" "${OPENCODE_API_KEY:-}" "${ZEN_API_KEY:-}"; do
    [ -n "$k" ] || continue
    if [ "$(classify_key "$k")" = "console" ]; then
        [ -z "$console_key" ] && console_key="$k"
    else
        [ -z "$zen_key" ] && zen_key="$k"
    fi
done

if [ -z "$console_key" ] && [ -z "$zen_key" ]; then
    error_out "missing OPENCODE_CONSOLE_KEY"
fi

tmp=$(mktemp)
hdr=$(mktemp)
trap 'rm -f "$tmp" "$hdr"' EXIT

remaining='null'
spent='null'
tokens='null'
bytes='null'
limits='[]'
errs=()
got_any=0

# --- Console usage (30d) + monthly member budget ---
# 24h CSV is often empty (UTC midnight window, free models billed $0). Empty
# 24h must not overwrite today's spend with zeros — sqlite can still fill it.
# 30d covers local today / week (Mon–Sun) / calendar month.
week_usd=""
week_tok=""
month_usd=""
month_tok=""
if [ -n "$console_key" ]; then
    code=$(curl -sS --max-time 20 -w '%{http_code}' -o "$tmp" \
        --get "${CONSOLE_URL}/api/v1/usage/export" \
        --header "Authorization: Bearer ${console_key}" \
        --header "Accept: text/csv" \
        --data-urlencode "scope=organization" \
        --data-urlencode "range=30d" || printf '000')

    if [ "$code" = "200" ]; then
        parsed=$(python3 - "$tmp" <<'PY'
import csv, sys
from datetime import datetime, timedelta

path = sys.argv[1]
today = datetime.now().astimezone().date()
week_start = today - timedelta(days=today.weekday())
month_start = today.replace(day=1)
today_cost = today_tok = week_cost = week_tok = month_cost = month_tok = 0
today_rows = week_rows = month_rows = rows = 0
with open(path, newline="", encoding="utf-8", errors="replace") as fh:
    for row in csv.DictReader(fh):
        rows += 1
        cost = int(row.get("cost_micro_cents") or 0)
        tok = (
            int(row.get("input_tokens") or 0)
            + int(row.get("output_tokens") or 0)
            + int(row.get("reasoning_tokens") or 0)
        )
        ts = (row.get("created_at") or "").strip()
        if not ts:
            continue
        try:
            d = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().date()
        except ValueError:
            continue
        if d >= month_start:
            month_cost += cost
            month_tok += tok
            month_rows += 1
        if d >= week_start:
            week_cost += cost
            week_tok += tok
            week_rows += 1
        if d == today:
            today_cost += cost
            today_tok += tok
            today_rows += 1
print(f"{today_cost} {today_tok} {week_cost} {week_tok} {month_cost} {month_tok} {today_rows} {week_rows} {month_rows} {rows}")
PY
) || true
        if [ -n "$parsed" ]; then
            read -r today_cost today_tok week_cost week_tok month_cost month_tok today_rows week_rows month_rows csv_rows <<<"$parsed"
            got_any=1
            if [ "${today_rows:-0}" -gt 0 ]; then
                spent=$(awk -v c="${today_cost:-0}" 'BEGIN { printf "%.6f", c / 100000000 }')
                tokens="${today_tok:-0}"
                bytes=$(awk -v t="$tokens" 'BEGIN { printf "%.0f", t * 4 }')
            fi
            week_usd=$(awk -v c="${week_cost:-0}" 'BEGIN { printf "%.6f", c / 100000000 }')
            week_tok="${week_tok:-0}"
            month_usd=$(awk -v c="${month_cost:-0}" 'BEGIN { printf "%.6f", c / 100000000 }')
            month_tok="${month_tok:-0}"
        fi
    else
        errs+=("usage $(short_err "$code" "")")
    fi

    code=$(curl -sS --max-time 12 -D "$hdr" -o "$tmp" -w '%{http_code}' \
        --header "Authorization: Bearer ${console_key}" \
        --header "Accept: application/json" \
        "${CONSOLE_URL}/api/v1/budgets/members" || printf '000')

    if [ "$code" = "200" ]; then
        unit=$(awk 'BEGIN{IGNORECASE=1} /^x-console-money-unit:/ { gsub(/\r/,""); print $2 }' "$hdr")
        [ -n "$unit" ] || unit="microcent"
        case "$unit" in
            microcent|microcents) div=100000000 ;;
            ten_microcents) div=10000000 ;;
            dollar|usd|dollars) div=1 ;;
            *) div=100000000 ;;
        esac

        budget_json=$(jq -c --argjson div "$div" '
            def members:
                if type == "array" then .
                elif (.members | type) == "array" then .members
                elif (.data | type) == "array" then .data
                elif (.data.members | type) == "array" then .data.members
                else [] end;
            def num(v):
                if v == null or v == "" then null
                else (v | tostring | tonumber? // null) end;
            def money(m):
                num(m.limit_micro_cents // m.limit // m.budget // m.budget_limit // m.monthly_limit // m.budget_dollars);
            def spend(m):
                num(m.spent_micro_cents // m.spend // m.spent // m.usage // m.spend_this_month // m.used // m.spend_cents) // 0;
            (members) as $ms |
            {
                limit: ([ $ms[] | money(.) | select(. != null) ] | if length == 0 then null else add end),
                spend: ([ $ms[] | spend(.) ] | add),
                unlimited: (([ $ms[] | money(.) ] | any(. == null)) or ($ms | length == 0))
            } |
            {
                limit_usd: (if .limit == null then null else (.limit / $div) end),
                spend_usd: (.spend / $div),
                unlimited: .unlimited
            }
        ' "$tmp" 2>/dev/null || printf 'null')

        if [ -n "$budget_json" ] && [ "$budget_json" != "null" ]; then
            got_any=1
            month_limit=$(printf '%s' "$budget_json" | jq -c '.limit_usd')
            month_spend=$(printf '%s' "$budget_json" | jq -c '.spend_usd')
            unlimited=$(printf '%s' "$budget_json" | jq -r '.unlimited')
            if [ "$unlimited" != "true" ] && [ "$month_limit" != "null" ]; then
                remaining=$(jq -n --argjson lim "$month_limit" --argjson sp "$month_spend" \
                    '($lim - $sp) | if . < 0 then 0 else . end')
                limits=$(jq -c --argjson used "$month_spend" --argjson limit "$month_limit" '
                    . + [{
                        period: "monthly",
                        used: $used,
                        limit: $limit,
                        percent: (if $limit == 0 then null else (($used / $limit) * 100) end)
                    }]
                ' <<<"$limits")
            fi
        fi
    else
        errs+=("budgets $(short_err "$code" "")")
    fi
fi

# --- Prepaid wallet remaining (browser console session) ---
session=$(console_session_cookie || true)
if [ -n "$session" ]; then
    if [ -z "$ORG_ID" ]; then
        org_code=$(curl -sS --max-time 10 -w '%{http_code}' -o "$tmp" \
            --header "Cookie: __Host-console_session=${session}" \
            --header "Accept: application/json" \
            "${CONSOLE_URL}/api/orgs" || printf '000')
        if [ "$org_code" = "200" ]; then
            ORG_ID=$(jq -r '.[0].id // empty' "$tmp" 2>/dev/null || true)
        fi
    fi
    if [ -n "$ORG_ID" ]; then
        wal_code=$(curl -sS --max-time 10 -w '%{http_code}' -o "$tmp" \
            --header "Cookie: __Host-console_session=${session}" \
            --header "x-org-id: ${ORG_ID}" \
            --header "Accept: application/json" \
            "${CONSOLE_URL}/api/billing/status" || printf '000')
        if [ "$wal_code" = "200" ]; then
            avail=$(jq -r '.availableMicroCents // .balanceMicroCents // empty' "$tmp" 2>/dev/null || true)
            if [ -n "$avail" ] && [ "$avail" != "null" ]; then
                remaining=$(awk -v c="$avail" 'BEGIN { printf "%.6f", (c+0) / 100000000 }')
                got_any=1
            fi
        fi
    fi
fi

# --- Zen key: confirm it works; Go windows are optional ---
if [ -n "$zen_key" ]; then
    zcode=$(curl -sS --max-time 8 -w '%{http_code}' -o "$tmp" \
        --header "Authorization: Bearer ${zen_key}" \
        --header "Accept: application/json" \
        "https://opencode.ai/zen/v1/models" || printf '000')
    if [ "$zcode" = "200" ]; then
        got_any=1
    elif [ -z "$console_key" ]; then
        errs+=("zen $(short_err "$zcode" "")")
    fi

    gcode=$(curl -sS --max-time 8 -w '%{http_code}' -o "$tmp" \
        --header "Authorization: Bearer ${zen_key}" \
        --header "Accept: application/json" \
        "https://opencode.ai/zen/go/v1/usage" || printf '000')
    if [ "$gcode" = "200" ]; then
        go_limits=$(jq -c '
            [.usage | to_entries[]? | select(.value.percent != null) |
             {period: ("go-" + .key), used: .value.percent, limit: 100,
              percent: .value.percent}]
        ' "$tmp" 2>/dev/null || printf '[]')
        if [ -n "$go_limits" ] && [ "$go_limits" != "[]" ]; then
            limits=$(jq -c --argjson extra "$go_limits" '. + $extra' <<<"$limits")
            got_any=1
        fi
    fi
fi

# --- Local today's spend from opencode.db (works with Zen keys) ---
if [ "$spent" = "null" ] && command -v sqlite3 >/dev/null 2>&1 && [ -f "$OPENCODE_DB" ]; then
    start_ms=$(date -d "$(date +%F) 00:00:00" +%s)000
    local_row=$(timeout 8 sqlite3 -batch -noheader "file:${OPENCODE_DB}?mode=ro" <<SQL
SELECT
  COALESCE(SUM(CASE WHEN json_type(data,'\$.cost') IN ('integer','real')
                    THEN json_extract(data,'\$.cost') ELSE 0 END), 0),
  COALESCE(SUM(
    COALESCE(json_extract(data,'\$.tokens.total'),
      COALESCE(json_extract(data,'\$.tokens.input'),0)
      + COALESCE(json_extract(data,'\$.tokens.output'),0)
      + COALESCE(json_extract(data,'\$.tokens.reasoning'),0))
  ), 0)
FROM session_message
WHERE time_created >= ${start_ms} AND type = 'assistant';
SQL
    ) || true
    if [ -n "$local_row" ]; then
        cost_local=${local_row%%|*}
        tok_local=${local_row##*|}
        spent=$(awk -v c="${cost_local:-0}" 'BEGIN { printf "%.6f", c+0 }')
        tokens=$(awk -v t="${tok_local:-0}" 'BEGIN { printf "%.0f", t+0 }')
        bytes=$(awk -v t="$tokens" 'BEGIN { printf "%.0f", t * 4 }')
        got_any=1
    fi
fi

if [ -n "$DAILY_LIMIT" ] && [ "$DAILY_LIMIT" != "null" ] && [ "$spent" != "null" ]; then
    limits=$(jq -c --argjson used "$spent" --argjson limit "$DAILY_LIMIT" '
        . + [{
            period: "daily",
            used: $used,
            limit: $limit,
            percent: (if $limit == 0 then null else (($used / $limit) * 100) end)
        }]
    ' <<<"$limits")
fi

add_spent weekly "${week_usd:-}" "${week_tok:-null}"
add_spent monthly "${month_usd:-}" "${month_tok:-null}"

ok="true"
err_msg=""
if [ ${#errs[@]} -gt 0 ]; then
    if printf '%s\n' "${errs[@]}" | grep -q 'forbidden'; then
        err_msg="Console 403: recreate oc_sk_ with All (usage+budgets), not inference-only"
    else
        err_msg=$(printf '%s; ' "${errs[@]}")
        err_msg="${err_msg%; }"
    fi
fi
if [ "$got_any" -eq 0 ]; then
    ok="false"
    [ -n "$err_msg" ] || err_msg="no OpenCode data"
fi

spent_json="$spent"
[ -n "$spent_json" ] || spent_json='null'
tokens_json="$tokens"
[ -n "$tokens_json" ] || tokens_json='null'
bytes_json="$bytes"
[ -n "$bytes_json" ] || bytes_json='null'
remaining_json="$remaining"
[ -n "$remaining_json" ] || remaining_json='null'

emit "$ok" "$remaining_json" "$spent_json" "$tokens_json" "$bytes_json" "$limits" "$err_msg"
