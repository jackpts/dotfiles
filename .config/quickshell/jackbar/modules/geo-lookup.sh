#!/usr/bin/env bash
# geo-lookup.sh <ip> — resolve a public IP to "Country|CountryCode|City".
# Prints "||" on failure or empty input.
#
# Caching (two layers, so we don't hammer the geo API):
#   1. On-disk per-IP cache: ${XDG_CACHE_HOME:-$HOME/.cache}/jackbar/geo/<ip>,
#      valid for 7 days (IP -> country mappings are stable).
#   2. The QML caller only invokes this script when the public IP changed
#      (tracked via _lastGeoIp), so repeated polls for the same IP never
#      reach the network at all.

ip="${1:-}"
[ -n "$ip" ] || { echo "||"; exit 0; }

# Basic sanity: plausible IP characters only (IPv4 + IPv6).
case "$ip" in
    *[!0-9a-fA-F.:]*) echo "||"; exit 0 ;;
esac

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/jackbar/geo"
safe=$(printf '%s' "$ip" | tr -c 'a-zA-Z0-9' '_')
cache_file="$cache_dir/$safe"
TTL=604800 # 7 days in seconds

# ip-api.com returns "City of London" style names — show just "London".
strip_city_prefix() {
    case "$1" in
        'City of '*) printf '%s' "${1#'City of '}" ;;
        *) printf '%s' "$1" ;;
    esac
}

if [ -f "$cache_file" ]; then
    mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    if [ $(( $(date +%s) - mtime )) -lt "$TTL" ]; then
        cached=$(cat "$cache_file" 2>/dev/null)
        # Normalize old cache entries (e.g. stored "City of London").
        c_country=$(printf '%s' "$cached" | cut -d'|' -f1)
        c_code=$(printf '%s' "$cached" | cut -d'|' -f2)
        c_city=$(strip_city_prefix "$(printf '%s' "$cached" | cut -d'|' -f3)")
        norm="$c_country|$c_code|$c_city"
        [ "$norm" != "$cached" ] && printf '%s\n' "$norm" > "$cache_file" 2>/dev/null
        printf '%s\n' "$norm"
        exit 0
    fi
fi

resp=$(curl -s --max-time 4 "http://ip-api.com/json/${ip}?fields=status,message,country,countryCode,city,query" 2>/dev/null)
[ -n "$resp" ] || { echo "||"; exit 0; }

country=""; code=""; city=""
if command -v jq >/dev/null 2>&1; then
    [ "$(printf '%s' "$resp" | jq -r '.status // empty' 2>/dev/null)" = "success" ] || { echo "||"; exit 0; }
    country=$(printf '%s' "$resp" | jq -r '.country // empty' 2>/dev/null)
    code=$(printf '%s' "$resp" | jq -r '.countryCode // empty' 2>/dev/null)
    city=$(printf '%s' "$resp" | jq -r '.city // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    parsed=$(printf '%s' "$resp" | python3 -c \
        "import sys,json
try:
    d = json.load(sys.stdin)
    assert d.get('status') == 'success'
    print(d.get('country', '') + '|' + d.get('countryCode', '') + '|' + d.get('city', ''))
except Exception:
    pass" 2>/dev/null)
    country=$(printf '%s' "$parsed" | cut -d'|' -f1)
    code=$(printf '%s' "$parsed" | cut -d'|' -f2)
    city=$(printf '%s' "$parsed" | cut -d'|' -f3)
else
    country=$(printf '%s' "$resp" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
    code=$(printf '%s' "$resp" | sed -n 's/.*"countryCode":"\([^"]*\)".*/\1/p')
    city=$(printf '%s' "$resp" | sed -n 's/.*"city":"\([^"]*\)".*/\1/p')
fi

# Strip pipes / control chars and cap length (tooltip safety).
country=$(printf '%s' "$country" | tr -d '|\r\n' | cut -c1-64)
code=$(printf '%s' "$code" | tr -d '|\r\n' | cut -c1-8)
city=$(strip_city_prefix "$(printf '%s' "$city" | tr -d '|\r\n' | cut -c1-64)")

[ -n "$country" ] || [ -n "$code" ] || { echo "||"; exit 0; }

out="$country|$code|$city"
mkdir -p "$cache_dir" 2>/dev/null
printf '%s\n' "$out" > "$cache_file" 2>/dev/null
printf '%s\n' "$out"
