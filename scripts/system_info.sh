#!/bin/bash

# System Information Script for Waybar
# Provides comprehensive system information with caching for performance

set -euo pipefail

# Configuration
readonly CACHE_DIR="$HOME/.cache/system_info"
readonly CACHE_FILE="$CACHE_DIR/system_info.json"
readonly CACHE_DURATION=30  # seconds

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

# Check if cache is valid
is_cache_valid() {
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [[ $cache_age -lt $CACHE_DURATION ]]; then
            return 0
        fi
    fi
    return 1
}

# Get system information
get_system_info() {
    local uptime cpu_temp cpu_usage memory_usage
    
    # Get uptime in a more readable format
    uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")
    
    # Get CPU temperature
    cpu_temp=$(cat /sys/class/hwmon/hwmon0/temp1_input 2>/dev/null | awk '{print $1/1000}' || echo "N/A")
    
    # Get CPU usage (simplified)
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0")
    
    # Get memory usage
    memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}' || echo "0")
    
    echo "{\"uptime\":\"$uptime\",\"cpu_temp\":\"$cpu_temp\",\"cpu_usage\":\"$cpu_usage\",\"memory_usage\":\"$memory_usage\"}"
}

# Get cached system info or generate new
get_cached_system_info() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
    else
        local system_info
        system_info=$(get_system_info)
        echo "$system_info" > "$CACHE_FILE"
        echo "$system_info"
    fi
}

# Main function
main() {
    local system_info
    system_info=$(get_cached_system_info)
    
    # Output JSON for Waybar
    printf '{"text": "System Info", "tooltip": "%s", "class": "system-info"}\n' "$system_info"
}

# Run main function
main "$@"