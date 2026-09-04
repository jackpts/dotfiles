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

# GPU temperature - nvidia-smi first, then hwmon fallbacks (amdgpu, nouveau, etc.)
get_gpu_temperature() {
    local temp_raw="" temp_celsius=""

    if command -v nvidia-smi >/dev/null 2>&1; then
        temp_celsius=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
        if [[ -n "$temp_celsius" && "$temp_celsius" =~ ^[0-9]+$ ]]; then
            echo "GPU Temperature: ${temp_celsius}°C"
            return
        fi
    fi

    for hwmon_path in /sys/class/hwmon/hwmon{0..9}; do
        if [ -f "$hwmon_path/name" ]; then
            local sensor_name
            sensor_name=$(cat "$hwmon_path/name" 2>/dev/null)
            if [[ "$sensor_name" =~ ^(amdgpu|nouveau|radeon|nvidia)$ ]]; then
                temp_raw=$(cat "$hwmon_path/temp1_input" 2>/dev/null)
                if [ -n "$temp_raw" ]; then
                    temp_celsius=$((temp_raw / 1000))
                    echo "GPU Temperature: ${temp_celsius}°C"
                    return
                fi
            fi
        fi
    done

    echo "GPU Temperature: N/A"
}

# Top memory consumers: aggregate by app name, max 10, hide below 1% RAM
get_top_memory_procs() {
    ps -eo comm,%mem --sort=-%mem --no-headers |
        awk '
            {
                mem[$1] += $2 + 0
            }
            END {
                for (name in mem)
                    printf "%s %f\n", name, mem[name]
            }
        ' | sort -k2 -nr |
        awk '
            $2 + 0 >= 1.0 {
                printf "%s: %.1f%%<br/>", $1, $2 + 0
                if (++n >= 10) exit
            }
        '
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

    local top_procs gpu_temp_line
    top_procs=$(get_top_memory_procs)
    gpu_temp_line=$(get_gpu_temperature)

    local tooltip="${gpu_temp_line}<br/>RAM Usage: ${used_gb}/${total_gb} Gb (${usage_percent}%)<br/>Available: ${available_gb} Gb<hr/>${top_procs}"
    
    # Output JSON for Quickshell/Waybar
    printf '{"text": "%s %d/%d Gb", "tooltip": "%s", "class": "%s", "percentage": %d}\n' \
        "$icon" "$used_gb" "$total_gb" "$tooltip" "$class" "$usage_percent"
}

# Run main function
main "$@"
