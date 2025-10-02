#!/bin/bash

# Sorted Taskbar Script for Waybar
# Provides window information sorted by workspace and focus order

set -euo pipefail

# Configuration
readonly MODULE_CLASS="taskbar-sorted"
readonly TOOLTIP_TEXT="Taskbar"

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

# Check dependencies
check_dependencies() {
    if ! command -v swaymsg >/dev/null 2>&1; then
        log_error "swaymsg not found"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq not found"
        exit 1
    fi
}

# Get all windows sorted by workspace, then by focus order
get_sorted_windows() {
    local windows_json
    
    windows_json=$(swaymsg -t get_tree 2>/dev/null | jq -r '
        def windows:
            .. | select(.type? == "con" and (.app_id? or .window_properties?.class?));
        
        def get_workspace_num:
            [.. | select(.type? == "workspace")] | first | .num;
        
        [windows | {
            workspace: get_workspace_num,
            app_id: (.app_id // .window_properties.class),
            name: .name,
            focused: .focused,
            id: .id
        }] | 
        group_by(.workspace) | 
        map(sort_by(.id)) | 
        flatten | 
        @json
    ' 2>/dev/null)
    
    if [[ -z "$windows_json" ]]; then
        log_error "Failed to get window information from sway"
        return 1
    fi
    
    echo "$windows_json"
}

# Main function
main() {
    check_dependencies
    
    local windows_json
    windows_json=$(get_sorted_windows) || {
        log_error "Failed to get sorted windows"
        exit 1
    }
    
    # Output JSON for waybar custom module
    printf '{"text": "", "tooltip": "%s", "class": "%s", "windows": %s}\n' \
        "$TOOLTIP_TEXT" "$MODULE_CLASS" "$windows_json"
}

# Run main function
main "$@"