#!/bin/bash
# Enhanced Public IP Script for Waybar
# Shows public IP with country flag emoji and country/region/city tooltip
# Usage: 
#   get_public_ip.sh          - returns just the IP (backward compatible)
#   get_public_ip.sh --json   - returns JSON with flag, IP, and tooltip
# Dependencies: curl, jq


# Function to get IP and country info from ipinfo.io
get_ip_info_from_ipinfo() {
    local info=$(timeout 5 curl -s "http://ipinfo.io/json" 2>/dev/null)
    if [ -n "$info" ] && echo "$info" | jq -e '.ip' >/dev/null 2>&1; then
        local ip=$(echo "$info" | jq -r '.ip // ""')
        local country=$(echo "$info" | jq -r '.country // ""')
        local region=$(echo "$info" | jq -r '.region // ""')
        local city=$(echo "$info" | jq -r '.city // ""')
        
        if [ -n "$ip" ]; then
            echo "$ip|$country|$region|$city"
            return 0
        fi
    fi
    return 1
}

# Function to get IP and country info from ip-api.com
get_ip_info_from_ipapi() {
    local info=$(timeout 5 curl -s "http://ip-api.com/json/" 2>/dev/null)
    if [ -n "$info" ] && echo "$info" | jq -e '.query' >/dev/null 2>&1; then
        local ip=$(echo "$info" | jq -r '.query // ""')
        local country=$(echo "$info" | jq -r '.country // ""')
        local region=$(echo "$info" | jq -r '.regionName // ""')
        local city=$(echo "$info" | jq -r '.city // ""')
        
        if [ -n "$ip" ]; then
            echo "$ip|$country|$region|$city"
            return 0
        fi
    fi
    return 1
}

# Function to get just IP as fallback
get_ip_only() {
    local ip=$(timeout 3 curl -s https://api.ipify.org 2>/dev/null || timeout 3 curl -s https://checkip.amazonaws.com 2>/dev/null | tr -d '\n\r')
    if [ -n "$ip" ]; then
        echo "$ip|||"
        return 0
    fi
    return 1
}

# Function to get local IP as last resort
get_local_ip() {
    local ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    if [ -n "$ip" ]; then
        echo "$ip|Local|Local|Local"
        return 0
    fi
    echo "No IP|Unknown|Unknown|Unknown"
}

# Try different methods to get IP and location info
ip_info=""
if ip_info=$(get_ip_info_from_ipinfo); then
    : # Success
elif ip_info=$(get_ip_info_from_ipapi); then
    : # Success with fallback
elif ip_info=$(get_ip_only); then
    : # Got IP only
else
    ip_info=$(get_local_ip)
fi

# Parse the result
IFS='|' read -r PUBLIC_IP COUNTRY REGION CITY <<< "$ip_info"

# Function to get country flag emoji from country code
get_country_flag() {
    case "$1" in
        "PL") echo "🇵🇱" ;;
        "US") echo "🇺🇸" ;;
        "CA") echo "🇨🇦" ;;
        "GB") echo "🇬🇧" ;;
        "DE") echo "🇩🇪" ;;
        "FR") echo "🇫🇷" ;;
        "IT") echo "🇮🇹" ;;
        "ES") echo "🇪🇸" ;;
        "NL") echo "🇳🇱" ;;
        "SE") echo "🇸🇪" ;;
        "NO") echo "🇳🇴" ;;
        "DK") echo "🇩🇰" ;;
        "FI") echo "🇫🇮" ;;
        "RU") echo "🇷🇺" ;;
        "UA") echo "🇺🇦" ;;
        "CZ") echo "🇨🇿" ;;
        "SK") echo "🇸🇰" ;;
        "HU") echo "🇭🇺" ;;
        "AT") echo "🇦🇹" ;;
        "CH") echo "🇨🇭" ;;
        "JP") echo "🇯🇵" ;;
        "KR") echo "🇰🇷" ;;
        "CN") echo "🇨🇳" ;;
        "AU") echo "🇦🇺" ;;
        "NZ") echo "🇳🇿" ;;
        "BR") echo "🇧🇷" ;;
        "MX") echo "🇲🇽" ;;
        "IN") echo "🇮🇳" ;;
        "SG") echo "🇸🇬" ;;
        "HK") echo "🇭🇰" ;;
        "TW") echo "🇹🇼" ;;
        "TH") echo "🇹🇭" ;;
        "VN") echo "🇻🇳" ;;
        "ID") echo "🇮🇩" ;;
        "MY") echo "🇲🇾" ;;
        "PH") echo "🇵🇭" ;;
        "ZA") echo "🇿🇦" ;;
        "EG") echo "🇪🇬" ;;
        "IL") echo "🇮🇱" ;;
        "TR") echo "🇹🇷" ;;
        "GR") echo "🇬🇷" ;;
        "PT") echo "🇵🇹" ;;
        "BE") echo "🇧🇪" ;;
        "LU") echo "🇱🇺" ;;
        "IE") echo "🇮🇪" ;;
        "IS") echo "🇮🇸" ;;
        "RO") echo "🇷🇴" ;;
        "BG") echo "🇧🇬" ;;
        "HR") echo "🇭🇷" ;;
        "SI") echo "🇸🇮" ;;
        "LT") echo "🇱🇹" ;;
        "LV") echo "🇱🇻" ;;
        "EE") echo "🇪🇪" ;;
        "AR") echo "🇦🇷" ;;
        "CL") echo "🇨🇱" ;;
        "CO") echo "🇨🇴" ;;
        "PE") echo "🇵🇪" ;;
        "VE") echo "🇻🇪" ;;
        "Local") echo "🏠" ;;
        *) echo "🌍" ;;
    esac
}

# Get country flag
COUNTRY_FLAG=$(get_country_flag "$COUNTRY")

# Create tooltip text
if [ "$COUNTRY" = "Local" ]; then
    TOOLTIP="Local Network IP"
elif [ -n "$COUNTRY" ] && [ "$COUNTRY" != "" ]; then
    TOOLTIP="$COUNTRY"
    [ -n "$REGION" ] && [ "$REGION" != "" ] && TOOLTIP="$TOOLTIP, $REGION"
    [ -n "$CITY" ] && [ "$CITY" != "" ] && TOOLTIP="$TOOLTIP, $CITY"
else
    TOOLTIP="Location: Unknown"
fi

# Check if we should output JSON (for Waybar) or just IP
if [ "$1" = "--json" ]; then
    # Use jq to create properly formatted and escaped JSON
    if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "No IP" ]; then
        jq -n -c \
            --arg text "🌐 No IP" \
            --arg tooltip "Unable to retrieve public IP" \
            --arg class "public-ip-error" \
            '{text: $text, tooltip: $tooltip, class: $class}' 2>/dev/null
    else
        jq -n -c \
            --arg text "$COUNTRY_FLAG $PUBLIC_IP" \
            --arg tooltip "$TOOLTIP" \
            --arg class "public-ip" \
            '{text: $text, tooltip: $tooltip, class: $class}' 2>/dev/null
    fi
else
    # Output just the IP address (for backward compatibility)
    echo "$PUBLIC_IP"
fi
