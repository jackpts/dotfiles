#!/usr/bin/env bash
# billing-status.sh — poll enabled AI billing plugins and emit JSON for jackbar.
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins"
PROVIDERS_FILE="${BILLING_PROVIDERS_FILE:-$SCRIPT_DIR/providers.json}"
SECRETS_FILE="${BILLING_SECRETS_FILE:-$SCRIPT_DIR/secrets.env}"
FALLBACK_ENV="${BILLING_FALLBACK_ENV:-$HOME/scripts/.env}"

emit_error() {
    local msg="$1"
    jq -n --arg err "$msg" '{ok:false, warn_percent:70, critical_percent:90, providers:[], error:$err}'
}

load_env_file() {
    local file="$1"
    local overwrite="${2:-0}"
    [ -f "$file" ] || return 0
    local line key val
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            if [[ "$val" == \"*\" ]]; then
                val="${val#\"}"
                val="${val%\"}"
            elif [[ "$val" == \'*\' ]]; then
                val="${val#\'}"
                val="${val%\'}"
            fi
            if [ "$overwrite" = "1" ] || [ -z "${!key:-}" ]; then
                export "$key=$val"
            fi
        fi
    done < "$file"
}

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' '{"ok":false,"warn_percent":70,"critical_percent":90,"providers":[],"error":"jq is required"}'
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    emit_error "curl is required"
    exit 0
fi

if [ ! -f "$PROVIDERS_FILE" ]; then
    emit_error "missing providers.json"
    exit 0
fi

# secrets.env wins; fill gaps from $HOME/scripts/.env
load_env_file "$SECRETS_FILE" 1
load_env_file "$FALLBACK_ENV" 0

warn_percent=$(jq -r '.warn_percent // 70' "$PROVIDERS_FILE")
critical_percent=$(jq -r '.critical_percent // 90' "$PROVIDERS_FILE")
poll_seconds=$(jq -r '.poll_seconds // 300' "$PROVIDERS_FILE")

results='[]'
while IFS= read -r prov; do
    [ -n "$prov" ] || continue
    id=$(printf '%s' "$prov" | jq -r '.id // empty')
    name=$(printf '%s' "$prov" | jq -r '.name // empty')
    plugin=$(printf '%s' "$prov" | jq -r '.plugin // empty')
    dashboard=$(printf '%s' "$prov" | jq -r '.dashboard_url // empty')

    stub() {
        local err="$1"
        jq -n \
            --arg id "$id" \
            --arg name "$name" \
            --arg url "$dashboard" \
            --arg err "$err" \
            '{id:$id, name:$name, dashboard_url:$url, ok:false, remaining_usd:null, spent_today_usd:null, tokens_today:null, bytes_est:null, limits:[], error:$err}'
    }

    if [ -z "$plugin" ] || [ "$plugin" = "todo" ]; then
        continue
    fi

    plugin_path="$PLUGIN_DIR/${plugin}.sh"
    if [ ! -x "$plugin_path" ]; then
        if [ -f "$plugin_path" ]; then
            chmod +x "$plugin_path" 2>/dev/null || true
        fi
    fi
    if [ ! -f "$plugin_path" ]; then
        row=$(stub "plugin ${plugin}.sh not found")
        results=$(jq -c --argjson row "$row" '. + [$row]' <<<"$results")
        continue
    fi

    raw=""
    if ! raw=$(timeout 40 bash "$plugin_path" "$prov" 2>/dev/null); then
        row=$(stub "plugin failed")
        results=$(jq -c --argjson row "$row" '. + [$row]' <<<"$results")
        continue
    fi

    if ! printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
        row=$(stub "plugin returned invalid JSON")
        results=$(jq -c --argjson row "$row" '. + [$row]' <<<"$results")
        continue
    fi

    row=$(jq -n -c \
        --argjson p "$prov" \
        --argjson r "$raw" \
        '$r + {id: $p.id, name: $p.name, dashboard_url: ($p.dashboard_url // "")}')
    results=$(jq -c --argjson row "$row" '. + [$row]' <<<"$results")
done < <(jq -c '.providers[]? | select(.enabled == true)' "$PROVIDERS_FILE")

jq -n \
    --argjson warn "$warn_percent" \
    --argjson crit "$critical_percent" \
    --argjson poll "$poll_seconds" \
    --argjson providers "$results" \
    '{ok:true, warn_percent:$warn, critical_percent:$crit, poll_seconds:$poll, providers:$providers, error:null}'
