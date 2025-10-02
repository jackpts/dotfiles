#!/usr/bin/env bash

# Enhanced System Monitor Launcher
# Launches btop with optimal terminal configuration

set -euo pipefail

# Configuration
readonly WINDOW_TITLE="System Monitor"
readonly WINDOW_CLASS="btop"
readonly KITTY_WIDTH=1400
readonly KITTY_HEIGHT=900
readonly ALACRITTY_COLS=120
readonly ALACRITTY_LINES=35
readonly GNOME_TERMINAL_GEOMETRY="120x35"

# Log function for debugging
log_info() {
    echo "INFO: $1" >&2
}

log_error() {
    echo "ERROR: $1" >&2
}

# Check if btop is available
check_btop() {
    if ! command -v btop >/dev/null 2>&1; then
        log_error "btop not found. Please install btop first."
        exit 1
    fi
}

# Launch with kitty (preferred terminal)
launch_kitty() {
    log_info "Launching btop with kitty"
    exec kitty \
        --title="$WINDOW_TITLE" \
        --class="$WINDOW_CLASS" \
        --override="remember_window_size=no" \
        --override="initial_window_width=$KITTY_WIDTH" \
        --override="initial_window_height=$KITTY_HEIGHT" \
        -e btop
}

# Launch with alacritty
launch_alacritty() {
    log_info "Launching btop with alacritty"
    exec alacritty \
        --title="$WINDOW_TITLE" \
        --class="$WINDOW_CLASS" \
        --option="window.dimensions.columns=$ALACRITTY_COLS" \
        --option="window.dimensions.lines=$ALACRITTY_LINES" \
        -e btop
}

# Launch with gnome-terminal
launch_gnome_terminal() {
    log_info "Launching btop with gnome-terminal"
    exec gnome-terminal \
        --title="$WINDOW_TITLE" \
        --geometry="$GNOME_TERMINAL_GEOMETRY" \
        -- btop
}

# Launch with generic terminal
launch_generic() {
    log_info "Launching btop with generic terminal"
    exec btop
}

# Main function
main() {
    check_btop
    
    # Try terminals in order of preference
    if command -v kitty >/dev/null 2>&1; then
        launch_kitty
    elif command -v alacritty >/dev/null 2>&1; then
        launch_alacritty
    elif command -v gnome-terminal >/dev/null 2>&1; then
        launch_gnome_terminal
    else
        log_error "No supported terminal emulator found"
        launch_generic
    fi
}

# Run main function
main "$@"