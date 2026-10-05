#!/usr/bin/env bash
# openrouter.sh — OpenRouter credits / usage plugin for jackbar billing.
# stdin unused; argv[1] is the provider object from providers.json.
set -euo pipefail
export LC_ALL=C

PROVIDER_JSON="${1:-{}}"
ID=$(printf '%s' "$PROVIDER_JSON" | jq -r '.id // "openrouter"' 2>/dev/null || printf 'openrouter')
DAILY_LIMIT=$(printf '%s' "$PROVIDER_JSON" | jq -r '.daily_limit_usd // empty' 2>/dev/null || true)
WEEKLY_LIMIT=$(printf '%s' "$PROVIDER_JSON" | jq -r '.weekly_limit_usd // empty' 2>/dev/null || true)

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

# Uncapped Daily/Weekly/Monthly spent row. Skips if that period already has a cap bar.
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

http_get() {
    local url="$1" key="$2" out="$3"
    curl -sS --max-time 8 -w '%{http_code}' -o "$out" \
        -H "Authorization: Bearer ${key}" \
        -H "Accept: application/json" \
        "$url" || printf '000'
}

if [ -z "${OPENROUTER_API_KEY:-}" ] && [ -z "${OPENROUTER_MGMT_KEY:-}" ]; then
    error_out "missing OPENROUTER_API_KEY / OPENROUTER_MGMT_KEY"
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

remaining='null'
spent='null'
tokens='null'
bytes='null'
limits='[]'
errs=()

# Account wallet remaining (credits page). Regular keys work; management key optional.
credits_key="${OPENROUTER_MGMT_KEY:-${OPENROUTER_API_KEY:-}}"
if [ -n "$credits_key" ]; then
    code=$(http_get "https://openrouter.ai/api/v1/credits" "$credits_key" "$tmp")
    if [ "$code" = "200" ]; then
        remaining=$(jq -c '
            ((.data.total_credits // 0) - (.data.total_usage // 0))
            | if . < 0 then 0 else . end
        ' "$tmp" 2>/dev/null || printf 'null')
        [ -n "$remaining" ] || remaining='null'
    elif [ "$code" != "401" ] && [ "$code" != "403" ] && [ "$code" != "000" ]; then
        errs+=("credits HTTP ${code}")
    fi
fi

# Per-key usage windows — regular API key.
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    code=$(http_get "https://openrouter.ai/api/v1/key" "$OPENROUTER_API_KEY" "$tmp")
    if [ "$code" = "200" ]; then
        spent=$(jq -c '.data.usage_daily // null' "$tmp" 2>/dev/null || printf 'null')
        [ -n "$spent" ] || spent='null'

        if [ "$remaining" = "null" ]; then
            remaining=$(jq -c '.data.limit_remaining // null' "$tmp" 2>/dev/null || printf 'null')
            [ -n "$remaining" ] || remaining='null'
        fi

        key_limit=$(jq -c '.data.limit // null' "$tmp" 2>/dev/null || printf 'null')
        key_reset=$(jq -r '.data.limit_reset // empty' "$tmp" 2>/dev/null || true)
        key_remaining=$(jq -c '.data.limit_remaining // null' "$tmp" 2>/dev/null || printf 'null')
        usage_daily=$(jq -c '.data.usage_daily // null' "$tmp" 2>/dev/null || printf 'null')
        usage_weekly=$(jq -c '.data.usage_weekly // null' "$tmp" 2>/dev/null || printf 'null')
        usage_monthly=$(jq -c '.data.usage_monthly // null' "$tmp" 2>/dev/null || printf 'null')

        if [ "$key_limit" != "null" ] && [ -n "$key_limit" ]; then
            period="${key_reset:-key}"
            [ -n "$period" ] || period="key"
            used_for_cap='null'
            case "$period" in
                daily) used_for_cap="$usage_daily" ;;
                weekly) used_for_cap="$usage_weekly" ;;
                monthly) used_for_cap="$usage_monthly" ;;
                *)
                    if [ "$key_remaining" != "null" ]; then
                        used_for_cap=$(jq -n --argjson lim "$key_limit" --argjson rem "$key_remaining" '$lim - $rem')
                    fi
                    ;;
            esac
            if [ "$used_for_cap" = "null" ] || [ -z "$used_for_cap" ]; then
                used_for_cap=$(jq -n --argjson lim "$key_limit" --argjson rem "${key_remaining:-null}" \
                    'if $rem == null then null else ($lim - $rem) end' 2>/dev/null || printf 'null')
            fi
            limits=$(jq -c --arg period "$period" --argjson used "$used_for_cap" --argjson limit "$key_limit" '
                . + [{
                    period: $period,
                    used: $used,
                    limit: $limit,
                    percent: (if $used == null or $limit == null or $limit == 0 then null
                              else (($used / $limit) * 100) end)
                }]
            ' <<<"$limits")
        fi

        if [ -n "$DAILY_LIMIT" ] && [ "$DAILY_LIMIT" != "null" ]; then
            limits=$(jq -c --argjson used "$usage_daily" --argjson limit "$DAILY_LIMIT" '
                . + [{
                    period: "daily",
                    used: $used,
                    limit: $limit,
                    percent: (if $used == null or $limit == 0 then null else (($used / $limit) * 100) end)
                }]
            ' <<<"$limits")
        fi
        if [ -n "$WEEKLY_LIMIT" ] && [ "$WEEKLY_LIMIT" != "null" ]; then
            limits=$(jq -c --argjson used "$usage_weekly" --argjson limit "$WEEKLY_LIMIT" '
                . + [{
                    period: "weekly",
                    used: $used,
                    limit: $limit,
                    percent: (if $used == null or $limit == 0 then null else (($used / $limit) * 100) end)
                }]
            ' <<<"$limits")
        fi

        # UTC day / week (Mon–Sun) / month from GET /api/v1/key. Daily dollars
        # already fill spent_today; skip a second Daily row.
        add_spent weekly "$usage_weekly"
        add_spent monthly "$usage_monthly"
    else
        errs+=("key HTTP ${code:-000}")
    fi
fi

# Token volume for today if the activity endpoint includes the current UTC day.
if [ -n "${OPENROUTER_MGMT_KEY:-}" ]; then
    today=$(date -u +%F)
    code=$(http_get "https://openrouter.ai/api/v1/activity?date=${today}" "$OPENROUTER_MGMT_KEY" "$tmp")
    if [ "$code" = "200" ]; then
        tok=$(jq -c '
            [.data[]? | ((.prompt_tokens // 0) + (.completion_tokens // 0) + (.reasoning_tokens // 0))]
            | add
        ' "$tmp" 2>/dev/null || printf 'null')
        if [ -n "$tok" ] && [ "$tok" != "null" ]; then
            tokens="$tok"
            bytes=$(jq -n --argjson t "$tokens" '$t * 4')
        fi
    fi
fi

ok="true"
err_msg=""
if [ "$remaining" = "null" ] && [ "$spent" = "null" ]; then
    ok="false"
    if [ ${#errs[@]} -gt 0 ]; then
        err_msg=$(IFS='; '; echo "${errs[*]}")
    else
        err_msg="no OpenRouter data"
    fi
fi

emit "$ok" "$remaining" "$spent" "$tokens" "$bytes" "$limits" "$err_msg"
