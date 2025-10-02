#!/usr/bin/env bash

# RAM Usage Monitor Script for Waybar
# Displays memory usage with visual indicators and tooltips

set -euo pipefail

# Configuration
readonly MEMINFO_FILE="/proc/meminfo"
readonly CRITICAL_THRESHOLD=90
readonly WARNING_THRESHOLD=70

# Icons for different usage levels
readonly ICON_CRITICAL="󰍛"
readonly ICON_WARNING="󰍛"
readonly ICON_NORMAL="󰘚"

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

# Check if meminfo file exists
check_meminfo() {
    if [[ ! -r "$MEMINFO_FILE" ]]; then
        log_error "Cannot read $MEMINFO_FILE"
        exit 1
    fi
}

# Get memory values from /proc/meminfo
get_memory_values() {
    local total_kb available_kb
    
    total_kb=$(awk '/^MemTotal:/ {print $2}' "$MEMINFO_FILE")
    available_kb=$(awk '/^MemAvailable:/ {print $2}' "$MEMINFO_FILE")
    
    if [[ -z "$total_kb" ]] || [[ -z "$available_kb" ]]; then
        log_error "Could not read memory values from $MEMINFO_FILE"
        exit 1
    fi
    
    echo "$total_kb $available_kb"
}

# Convert KB to GB with proper rounding
kb_to_gb() {
    local kb=$1
    echo $(((kb + 512000) / 1024 / 1024))
}

# Calculate memory usage and return formatted values
calculate_memory_usage() {
    local total_kb=$1
    local available_kb=$2
    local used_kb=$((total_kb - available_kb))
    
    local total_gb used_gb available_gb usage_percent
    
    total_gb=$(kb_to_gb "$total_kb")
    used_gb=$(kb_to_gb "$used_kb")
    available_gb=$(kb_to_gb "$available_kb")
    usage_percent=$((used_kb * 100 / total_kb))
    
    echo "$used_gb $total_gb $available_gb $usage_percent"
}

# Determine icon and class based on usage percentage
get_status_info() {
    local usage_percent=$1
    local icon class
    
    if [[ $usage_percent -ge $CRITICAL_THRESHOLD ]]; then
        icon="$ICON_CRITICAL"
        class="critical"
    elif [[ $usage_percent -ge $WARNING_THRESHOLD ]]; then
        icon="$ICON_WARNING"
        class="warning"
    else
        icon="$ICON_NORMAL"
        class="normal"
    fi
    
    echo "$icon $class"
}

# Main function
main() {
    check_meminfo
    
    local memory_values
    memory_values=$(get_memory_values)
    read -r total_kb available_kb <<< "$memory_values"
    
    local usage_values
    usage_values=$(calculate_memory_usage "$total_kb" "$available_kb")
    read -r used_gb total_gb available_gb usage_percent <<< "$usage_values"
    
    local status_info
    status_info=$(get_status_info "$usage_percent")
    read -r icon class <<< "$status_info"
    
    # Output JSON for Waybar
    printf '{"text": "%s %d/%d Gb", "tooltip": "RAM Usage: %d/%d Gb (%d%%)\\nAvailable: %d Gb", "class": "%s", "percentage": %d}\n' \
        "$icon" "$used_gb" "$total_gb" "$used_gb" "$total_gb" "$usage_percent" "$available_gb" "$class" "$usage_percent"
}

# Run main function
main "$@"
