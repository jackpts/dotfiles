#!/bin/bash

# Enhanced Wallpaper Restoration Script for Sway
# Ensures reliable wallpaper restoration on system startup with comprehensive error handling

set -euo pipefail

# Configuration
readonly LOG_FILE="$HOME/.local/share/waypaper.log"
readonly WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
readonly MAX_RETRIES=10
readonly RETRY_DELAY=2
readonly DISPLAY_TIMEOUT=20

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Logging functions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_error() {
    echo "ERROR: $1" >&2
    log_message "ERROR: $1"
}

log_info() {
    echo "INFO: $1" >&2
    log_message "INFO: $1"
}

# Check if waypaper is available
check_waypaper() {
    if ! command -v waypaper >/dev/null 2>&1; then
        log_error "waypaper command not found"
        return 1
    fi
    return 0
}

# Check if config exists
check_config() {
    if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
        log_error "waypaper config file not found at $WAYPAPER_CONFIG"
        return 1
    fi
    return 0
}

# Extract wallpaper path from config
get_wallpaper_path() {
    local wallpaper_path
    
    if [[ -f "$WAYPAPER_CONFIG" ]]; then
        wallpaper_path=$(grep '^wallpaper = ' "$WAYPAPER_CONFIG" | cut -d '=' -f 2 | tr -d ' ' | tr -d '"')
        echo "$wallpaper_path"
    fi
}

# Check if wallpaper file exists
check_wallpaper_file() {
    local wallpaper_path
    wallpaper_path=$(get_wallpaper_path)
    
    if [[ -z "$wallpaper_path" ]]; then
        log_error "No wallpaper path found in config"
        return 1
    fi
    
    # Expand tilde to home directory
    wallpaper_path=$(eval echo "$wallpaper_path")
    
    if [[ ! -f "$wallpaper_path" ]]; then
        log_error "Wallpaper file not found: $wallpaper_path"
        return 1
    fi
    
    log_info "Found wallpaper: $wallpaper_path"
    return 0
}

# Wait for display to be ready
wait_for_display() {
    local retries=0
    
    log_info "Waiting for display to be ready..."
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        if swaymsg -t get_outputs 2>/dev/null | grep -q "name"; then
            log_info "Display ready, proceeding with wallpaper restoration"
            return 0
        fi
        
        log_info "Waiting for display... (attempt $((retries + 1))/$MAX_RETRIES)"
        sleep $RETRY_DELAY
        retries=$((retries + 1))
    done
    
    log_error "Display not ready after $DISPLAY_TIMEOUT seconds"
    return 1
}

# Restore wallpaper using waypaper
restore_with_waypaper() {
    log_info "Executing: waypaper --restore"
    
    if waypaper --restore >> "$LOG_FILE" 2>&1; then
        log_info "SUCCESS: Wallpaper restored successfully"
        return 0
    else
        log_error "Failed to restore wallpaper with waypaper"
        return 1
    fi
}

# Main restoration function
restore_wallpaper() {
    log_info "Starting wallpaper restoration"
    
    # Check prerequisites
    if ! check_waypaper; then
        return 1
    fi
    
    if ! check_config; then
        return 1
    fi
    
    if ! check_wallpaper_file; then
        return 1
    fi
    
    # Wait for display to be ready
    if ! wait_for_display; then
        return 1
    fi
    
    # Restore wallpaper
    if ! restore_with_waypaper; then
        return 1
    fi
    
    log_info "Wallpaper restoration completed successfully"
    return 0
}

# Main function
main() {
    if restore_wallpaper; then
        exit 0
    else
        log_error "Wallpaper restoration failed"
        exit 1
    fi
}

# Run main function
main "$@"