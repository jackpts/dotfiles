#!/bin/bash

# Enhanced Application Launcher Script
# Launches applications using rofi

set -euo pipefail

# Configuration
readonly ROFI_THEME="$HOME/.config/rofi/catppuccin-mocha.rasi"
readonly ROFI_FALLBACK_THEME="$HOME/.config/rofi/style.rasi"

# Log function for debugging
log_error() {
    echo "ERROR: $1" >&2
}

log_info() {
    echo "INFO: $1" >&2
}

# Check if rofi is available
check_rofi() {
    if ! command -v rofi >/dev/null 2>&1; then
        log_error "rofi not found"
        return 1
    fi
    return 0
}

# Check if theme file exists
check_theme() {
    local theme_file=$1
    
    if [[ ! -f "$theme_file" ]]; then
        log_error "Theme file not found: $theme_file"
        return 1
    fi
    return 0
}

# Launch with rofi using specified theme
launch_rofi() {
    local theme_file=$1
    
    log_info "Launching rofi with theme: $theme_file"
    exec rofi -show drun -theme "$theme_file" -click-to-exit enabled
}

# Main function
main() {
    if ! check_rofi; then
        log_error "rofi not found"
        exit 1
    fi
    
    # Try primary theme first
    if check_theme "$ROFI_THEME"; then
        launch_rofi "$ROFI_THEME"
    # Try fallback theme
    elif check_theme "$ROFI_FALLBACK_THEME"; then
        launch_rofi "$ROFI_FALLBACK_THEME"
    else
        log_error "No valid rofi theme found"
        exit 1
    fi
}

# Run main function
main "$@"
