#!/bin/bash

# Home Directory Free Space Monitor for Waybar
# Displays available space in /home with visual indicators

set -euo pipefail

# Configuration
readonly HOME_MOUNT="/home"
readonly LOW_SPACE_THRESHOLD=10  # GB
readonly ICON_DISK="󰋜"

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

# Check if df command is available
check_dependencies() {
    if ! command -v df >/dev/null 2>&1; then
        log_error "df command not found"
        exit 1
    fi
}

# Get free space in GB
get_free_space() {
    local free_space
    
    # Get free space in GB, handling different df output formats
    free_space=$(df -BG "$HOME_MOUNT" 2>/dev/null | awk 'NR==2 {gsub(/G/, "", $4); print $4}' || \
                 df -h "$HOME_MOUNT" 2>/dev/null | awk 'NR==2 {gsub(/G/, "", $4); print $4}' || \
                 df "$HOME_MOUNT" 2>/dev/null | awk 'NR==2 {printf "%.0f", $4/1024/1024/1024}')
    
    if [[ -z "$free_space" ]] || [[ "$free_space" == "0" ]]; then
        log_error "Could not determine free space for $HOME_MOUNT"
        exit 1
    fi
    
    echo "$free_space"
}

# Determine CSS class based on free space
get_space_class() {
    local free_space=$1
    
    if [[ $free_space -lt $LOW_SPACE_THRESHOLD ]]; then
        echo "exceed"
    else
        echo "default"
    fi
}

# Main function
main() {
    check_dependencies
    
    local free_space
    free_space=$(get_free_space)
    
    local class
    class=$(get_space_class "$free_space")
    
    # Output JSON for Waybar
    printf '{"text": "%s %s Gb", "tooltip": "Home directory free space: %s Gb", "class": "%s"}\n' \
        "$ICON_DISK" "$free_space" "$free_space" "$class"
}

# Run main function
main "$@"
