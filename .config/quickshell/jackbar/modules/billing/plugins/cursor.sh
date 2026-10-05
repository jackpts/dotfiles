#!/usr/bin/env bash
# cursor.sh — Cursor spending plugin for jackbar billing.
# Auth: optional CURSOR_API_KEY, else the local IDE session in state.vscdb.
# Fallback: Zen/Firefox/LibreWolf cookie WorkosCursorSessionToken on cursor.com
# (dashboard usage when the IDE is closed / the local token returns 401/403).
# argv[1] is the provider object from providers.json.
set -euo pipefail
export LC_ALL=C

PROVIDER_JSON="${1:-{}}"
ID=$(printf '%s' "$PROVIDER_JSON" | jq -r '.id // "cursor"' 2>/dev/null || printf 'cursor')
DAILY_LIMIT=$(printf '%s' "$PROVIDER_JSON" | jq -r '.daily_limit_usd // empty' 2>/dev/null || true)
WEEKLY_LIMIT=$(printf '%s' "$PROVIDER_JSON" | jq -r '.weekly_limit_usd // empty' 2>/dev/null || true)
STATE_DB="${CURSOR_STATE_DB:-$HOME/.config/Cursor/User/globalStorage/state.vscdb}"

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
        --arg renew "${8:-}" \
        '{
            id: $id,
            ok: $ok,
            remaining_usd: $remaining,
            spent_today_usd: $spent,
            tokens_today: $tokens,
            bytes_est: $bytes,
            limits: $limits,
            error: (if $err == "" then null else $err end),
            renew_line: (if $renew == "" then null else $renew end)
        }'
}

error_out() {
    emit false null null null null '[]' "$1" ""
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

read_local_token() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        return 1
    fi
    [ -f "$STATE_DB" ] || return 1
    timeout 15 sqlite3 -batch -noheader "file:${STATE_DB}?mode=ro" \
        "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1;" 2>/dev/null \
        | tr -d '\r\n'
}

# Prints JSON {cookie, jwt} from CURSOR_SESSION_COOKIE or Zen/Firefox cookies.sqlite.
read_browser_session() {
    python3 - <<'PY'
import glob, json, os, shutil, sqlite3, tempfile, time, urllib.parse

def jwt_from(raw):
    if not raw:
        return ""
    value = urllib.parse.unquote(raw)
    if "::" in value:
        return value.split("::", 1)[1]
    return value

override = os.environ.get("CURSOR_SESSION_COOKIE", "").strip()
if override:
    print(json.dumps({"cookie": override, "jwt": jwt_from(override)}), end="")
    raise SystemExit(0)

now = time.time()
now_ms = now * 1000
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
                WHERE name = 'WorkosCursorSessionToken'
                  AND host IN ('cursor.com', '.cursor.com')
                """
            ).fetchall()
            con.close()
            for value, expiry in rows:
                if not value:
                    continue
                exp = expiry or 0
                if exp > 10_000_000_000:
                    if exp < now_ms:
                        continue
                elif exp and exp < now:
                    continue
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
    raw = best[1]
    print(json.dumps({"cookie": raw, "jwt": jwt_from(raw)}), end="")
PY
}

http_post() {
    local url="$1" tok="$2" body="$3" out="$4"
    curl -sS --max-time 10 -w '%{http_code}' -o "$out" \
        -X POST "$url" \
        -H "Authorization: Bearer ${tok}" \
        -H "Content-Type: application/json" \
        -H "Connect-Protocol-Version: 1" \
        -H "Accept: application/json" \
        -H "User-Agent: Cursor-Billing/1.0" \
        -H "Origin: https://cursor.com" \
        --data "$body" || printf '000'
}

http_cookie_post() {
    local url="$1" cookie="$2" body="$3" out="$4"
    curl -sS --max-time 10 -w '%{http_code}' -o "$out" \
        -X POST "$url" \
        -H "Cookie: WorkosCursorSessionToken=${cookie}" \
        -H "Content-Type: application/json" \
        -H "Connect-Protocol-Version: 1" \
        -H "Accept: application/json" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0" \
        -H "Origin: https://cursor.com" \
        -H "Referer: https://cursor.com/dashboard/spending" \
        --data "$body" || printf '000'
}

http_cookie_get() {
    local url="$1" cookie="$2" out="$3"
    curl -sS --max-time 8 -w '%{http_code}' -o "$out" \
        -H "Cookie: WorkosCursorSessionToken=${cookie}" \
        -H "Accept: application/json" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0" \
        -H "Origin: https://cursor.com" \
        -H "Referer: https://cursor.com/dashboard/spending" \
        "$url" || printf '000'
}

cursor_agg() {
    local start_ms="$1" dest="$2" end="$3"
    local body acode="000"
    body=$(jq -n --argjson start "$start_ms" --argjson end "$end" \
        '{teamId: -1, startDate: $start, endDate: $end}')
    if [ "$auth_mode" = "cookie" ]; then
        acode=$(http_cookie_post \
            "https://cursor.com/api/dashboard/get-aggregated-usage-events" \
            "$session_cookie" "$body" "$dest")
    else
        acode=$(http_post \
            "https://api2.cursor.sh/aiserver.v1.DashboardService/GetAggregatedUsageEvents" \
            "$token" "$body" "$dest")
        if [ "$acode" != "200" ]; then
            acode=$(http_post \
                "https://cursor.com/api/dashboard/get-aggregated-usage-events" \
                "$token" "$body" "$dest")
        fi
        if [ "$acode" != "200" ]; then
            load_browser_session
            if [ -n "$session_cookie" ]; then
                acode=$(http_cookie_post \
                    "https://cursor.com/api/dashboard/get-aggregated-usage-events" \
                    "$session_cookie" "$body" "$dest")
            fi
        fi
    fi
    printf '%s' "$acode"
}

parse_agg() {
    jq -c '
        def num(v):
            if v == null or v == "" then null
            else (v | tostring | tonumber? // null) end;
        def sum_field(name):
            ([.aggregations[]? | num(.[name]) // 0] | add);
        {
            spent: (
                (num(.totalCostCents) // ([.aggregations[]? | num(.totalCents) // 0] | add) // 0) / 100
            ),
            tokens: (
                (num(.totalInputTokens) // 0)
                + (num(.totalOutputTokens) // 0)
                + (sum_field("inputTokens"))
                + (sum_field("outputTokens"))
            )
        }
    ' "$1" 2>/dev/null || printf 'null'
}

auth_tokens=()
if [ -n "${CURSOR_API_KEY:-}" ]; then
    auth_tokens+=("$CURSOR_API_KEY")
fi
local_tok=$(read_local_token || true)
if [ -n "$local_tok" ]; then
    if [ "${#auth_tokens[@]}" -eq 0 ] || [ "$local_tok" != "${auth_tokens[0]}" ]; then
        auth_tokens+=("$local_tok")
    fi
fi

session_cookie=""
session_jwt=""
browser_loaded=0
load_browser_session() {
    if [ "$browser_loaded" = "1" ]; then
        return 0
    fi
    browser_loaded=1
    local raw
    raw=$(read_browser_session 2>/dev/null || true)
    if [ -n "$raw" ]; then
        session_cookie=$(printf '%s' "$raw" | jq -r '.cookie // empty' 2>/dev/null || true)
        session_jwt=$(printf '%s' "$raw" | jq -r '.jwt // empty' 2>/dev/null || true)
    fi
}

tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.stripe"' EXIT

remaining='null'
spent='null'
tokens='null'
bytes='null'
limits='[]'
token=""
auth_mode=""
code="000"

if [ "${#auth_tokens[@]}" -gt 0 ]; then
    for tok in "${auth_tokens[@]}"; do
        token="$tok"
        auth_mode="bearer"
        code=$(http_post \
            "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage" \
            "$token" '{}' "$tmp")
        if [ "$code" = "200" ]; then
            break
        fi
    done
fi

if [ "$code" != "200" ]; then
    load_browser_session
    if [ -n "$session_jwt" ]; then
        token="$session_jwt"
        auth_mode="bearer"
        code=$(http_post \
            "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage" \
            "$token" '{}' "$tmp")
    fi
fi

if [ "$code" != "200" ]; then
    load_browser_session
    if [ -n "$session_cookie" ]; then
        auth_mode="cookie"
        token=""
        code=$(http_cookie_post \
            "https://cursor.com/api/dashboard/get-current-period-usage" \
            "$session_cookie" '{}' "$tmp")
    fi
fi

if [ "$code" != "200" ]; then
    if [ "${#auth_tokens[@]}" -eq 0 ] && [ -z "$session_cookie" ] && [ -z "$session_jwt" ]; then
        error_out "missing CURSOR_API_KEY (or local Cursor session / cursor.com cookie in Zen)"
    fi
    if [ -z "$session_cookie" ] && [ -z "$session_jwt" ]; then
        error_out "usage HTTP ${code:-000} (log into cursor.com in Zen)"
    fi
    error_out "usage HTTP ${code:-000}"
fi

cycle_end_ms=$(jq -r '.billingCycleEnd // empty' "$tmp" 2>/dev/null || true)
renew_line=""
if [ -n "$cycle_end_ms" ] && [ "$cycle_end_ms" != "null" ]; then
    days=$(python3 -c '
from datetime import datetime
import sys
end = datetime.fromtimestamp(int(sys.argv[1]) / 1000).astimezone().date()
now = datetime.now().astimezone().date()
print(max(0, (end - now).days))
' "$cycle_end_ms" 2>/dev/null || true)
                if [ -n "$days" ]; then
        if [ "$days" = "1" ]; then
            renew_line="1 day until next auto-pay"
        else
            renew_line="${days} days until next auto-pay"
        fi
        scode="000"
        if [ "$auth_mode" = "cookie" ]; then
            scode=$(http_cookie_get \
                "https://cursor.com/api/auth/stripe" \
                "$session_cookie" "$tmp.stripe")
        else
            scode=$(curl -sS --max-time 8 -w '%{http_code}' -o "$tmp.stripe" \
                -H "Authorization: Bearer ${token}" \
                -H "Accept: application/json" \
                -H "User-Agent: Cursor-Billing/1.0" \
                -H "Origin: https://cursor.com" \
                "https://api2.cursor.sh/auth/full_stripe_profile" || printf '000')
            if [ "$scode" != "200" ]; then
                load_browser_session
                if [ -n "$session_cookie" ]; then
                    scode=$(http_cookie_get \
                        "https://cursor.com/api/auth/stripe" \
                        "$session_cookie" "$tmp.stripe")
                fi
            fi
        fi
        if [ "$scode" = "200" ]; then
            pending=$(jq -r '.pendingCancellationDate // empty' "$tmp.stripe" 2>/dev/null || true)
            status=$(jq -r '.subscriptionStatus // empty' "$tmp.stripe" 2>/dev/null || true)
            case "$status" in
                canceled|cancelled|incomplete_expired) pending="yes" ;;
            esac
            if [ -n "$pending" ] && [ "$pending" != "null" ]; then
                if [ "$days" = "1" ]; then
                    renew_line="1 day until cycle ends (no auto-pay)"
                else
                    renew_line="${days} days until cycle ends (no auto-pay)"
                fi
            fi
        fi
        rm -f "$tmp.stripe"
    fi
fi

parsed=$(jq -c '
    def num(v):
        if v == null or v == "" then null
        else (v | tostring | tonumber? // null) end;
    def cents(v):
        (num(v) as $n | if $n == null then null else ($n / 100) end);
    def nz(v): if v == null then 0 else v end;
    .planUsage as $p |
    .spendLimitUsage as $s |
    (cents($p.limit) // cents($s.pooledLimit)) as $incl_limit |
    (cents($p.includedSpend) // (
        if $incl_limit == null then cents($p.totalSpend)
        else ([nz(cents($p.totalSpend)), $incl_limit] | min)
        end
    )) as $incl_used |
    (cents($p.remaining) // (
        if $incl_limit == null then null
        else (($incl_limit - nz($incl_used)) | if . < 0 then 0 else . end)
        end
    )) as $incl_left |
    (nz(cents($p.totalSpend)) - nz($incl_used)) as $od_raw |
    (if $od_raw > 0.0005 then $od_raw else 0 end) as $od_used |
    (cents($s.pooledLimit) // cents($s.limit) // null) as $od_cap |
    {
        remaining: (if $incl_left == null then null elif $incl_left < 0 then 0 else $incl_left end),
        included_used: $incl_used,
        included_limit: $incl_limit,
        included_percent: (if $incl_limit == null or $incl_limit == 0 or $incl_used == null then null
                           else (($incl_used / $incl_limit) * 100 | if . > 100 then 100 else . end) end),
        ondemand_used: (if $od_used > 0 then $od_used else null end),
        ondemand_limit: $od_cap,
        ondemand_percent: (if $od_used > 0 and $od_cap != null and $od_cap != 0
                           then (($od_used / $od_cap) * 100) else null end)
    }
' "$tmp" 2>/dev/null || printf 'null')

if [ -z "$parsed" ] || [ "$parsed" = "null" ]; then
    error_out "unrecognized Cursor usage payload"
fi

remaining=$(printf '%s' "$parsed" | jq -c '.remaining')
incl_used=$(printf '%s' "$parsed" | jq -c '.included_used')
incl_limit=$(printf '%s' "$parsed" | jq -c '.included_limit')
incl_pct=$(printf '%s' "$parsed" | jq -c '.included_percent')
od_used=$(printf '%s' "$parsed" | jq -c '.ondemand_used')
od_limit=$(printf '%s' "$parsed" | jq -c '.ondemand_limit')
od_pct=$(printf '%s' "$parsed" | jq -c '.ondemand_percent')

limits='[]'
if [ "$incl_limit" != "null" ] || [ "$incl_used" != "null" ]; then
    limits=$(jq -n -c \
        --argjson used "$incl_used" \
        --argjson limit "$incl_limit" \
        --argjson percent "$incl_pct" \
        '[{period:"included", used:$used, limit:$limit, percent:$percent}]')
fi
if [ "$od_used" != "null" ]; then
    limits=$(jq -c \
        --argjson used "$od_used" \
        --argjson limit "$od_limit" \
        --argjson percent "$od_pct" \
        '. + [{period:"on-demand", used:$used, limit:$limit, percent:$percent}]' <<<"$limits")
fi

# Daily / weekly / monthly spend from aggregated events (local calendar).
read -r day_ms week_ms month_ms end_ms < <(python3 -c '
from datetime import datetime, timedelta
now = datetime.now().astimezone()
today = now.replace(hour=0, minute=0, second=0, microsecond=0)
week = today - timedelta(days=today.weekday())
month = today.replace(day=1)
print(
    int(today.timestamp() * 1000),
    int(week.timestamp() * 1000),
    int(month.timestamp() * 1000),
    int(now.timestamp() * 1000),
)
' 2>/dev/null || true)
if [ -z "${day_ms:-}" ] || [ -z "${end_ms:-}" ]; then
    day_ms=$(date -d "$(date +%F) 00:00:00" +%s)000
    end_ms=$(date +%s)000
    week_ms=""
    month_ms=""
fi

if [ -n "${day_ms:-}" ] && [ -n "${end_ms:-}" ]; then
    acode=$(cursor_agg "$day_ms" "$tmp" "$end_ms")
    if [ "$acode" = "200" ]; then
        today=$(parse_agg "$tmp")
        if [ -n "$today" ] && [ "$today" != "null" ]; then
            spent=$(printf '%s' "$today" | jq -c '.spent')
            tok=$(printf '%s' "$today" | jq -c '.tokens')
            if [ "$tok" != "null" ] && [ "$tok" != "0" ]; then
                tokens="$tok"
                bytes=$(jq -n --argjson t "$tokens" '$t * 4')
            fi
        fi
    fi

    if [ -n "${week_ms:-}" ]; then
        acode=$(cursor_agg "$week_ms" "$tmp" "$end_ms")
        if [ "$acode" = "200" ]; then
            week=$(parse_agg "$tmp")
            if [ -n "$week" ] && [ "$week" != "null" ]; then
                week_spent=$(printf '%s' "$week" | jq -c '.spent')
                week_tok=$(printf '%s' "$week" | jq -c '.tokens')
                if [ -n "$WEEKLY_LIMIT" ] && [ "$WEEKLY_LIMIT" != "null" ]; then
                    limits=$(jq -c --argjson used "$week_spent" --argjson limit "$WEEKLY_LIMIT" '
                        . + [{
                            period: "weekly",
                            used: $used,
                            limit: $limit,
                            percent: (if $used == null or $limit == 0 then null else (($used / $limit) * 100) end)
                        }]
                    ' <<<"$limits")
                else
                    add_spent weekly "$week_spent" "$week_tok"
                fi
            fi
        fi
    fi

    if [ -n "${month_ms:-}" ]; then
        acode=$(cursor_agg "$month_ms" "$tmp" "$end_ms")
        if [ "$acode" = "200" ]; then
            month=$(parse_agg "$tmp")
            if [ -n "$month" ] && [ "$month" != "null" ]; then
                month_spent=$(printf '%s' "$month" | jq -c '.spent')
                month_tok=$(printf '%s' "$month" | jq -c '.tokens')
                add_spent monthly "$month_spent" "$month_tok"
            fi
        fi
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

ok="true"
err_msg=""
if [ "$remaining" = "null" ] && [ "$incl_used" = "null" ] && [ "$spent" = "null" ]; then
    ok="false"
    err_msg="no Cursor spending data"
fi

emit "$ok" "$remaining" "$spent" "$tokens" "$bytes" "$limits" "$err_msg" "$renew_line"
