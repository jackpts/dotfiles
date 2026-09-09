#!/bin/bash

# Keyboard Layout Detection Script for Sway/Waybar
# Returns current keyboard layout in short format (EN/RU)

set -euo pipefail

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

# Check if required commands exist
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

# Get the active keyboard layout from sway
get_keyboard_layout() {
    local layout
    layout=$(swaymsg -t get_inputs 2>/dev/null | jq -r '.[] | select(.type == "keyboard" and has("xkb_layout_names")) | .xkb_active_layout_name' | head -1)
    
    if [[ -z "$layout" ]]; then
        log_error "Could not detect keyboard layout"
        return 1
    fi
    
    echo "$layout"
}

# Get short layout code as fallback
get_short_layout() {
    local short_layout
    short_layout=$(swaymsg -t get_inputs 2>/dev/null | jq -r '.[] | select(.type == "keyboard" and has("xkb_layout_names")) | .xkb_layout_names[.xkb_active_layout_index]' | head -1 | cut -c1-2 | tr '[:lower:]' '[:upper:]')
    
    if [[ -z "$short_layout" ]]; then
        log_error "Could not get short layout code"
        return 1
    fi
    
    echo "$short_layout"
}

# Main function
main() {
    check_dependencies
    
    local layout
    layout=$(get_keyboard_layout) || {
        log_error "Failed to get keyboard layout"
        exit 1
    }
    
    case "$layout" in
        "English (US)")
            echo "EN"
            ;;
        "Russian")
            echo "RU"
            ;;
        *)
            # Fallback: try to get short layout code
            local short_layout
            short_layout=$(get_short_layout) || {
                # Last resort: use first two characters of layout name
                echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]'
                return 0
            }
            
            if [[ "$short_layout" == "EN" ]] || [[ "$short_layout" == "RU" ]]; then
                echo "$short_layout"
            else
                echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]'
            fi
            ;;
    esac
}

# Run main function
main "$@"