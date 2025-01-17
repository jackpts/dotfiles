#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/walls/NY"
# WALLPAPER_DIR="$HOME/Pictures/walls/wallheaven.cc"
STYLE_FILE="$HOME/.config/wofi/menu.css"

SELECTED_WALLPAPER=$(find "$WALLPAPER_DIR" -type f -name '*.png' -o -name '*.jpg' | sed "s|^$WALLPAPER_DIR/||" | wofi --show dmenu --prompt "Select Wallpaper: " --style "$STYLE_FILE")

if [ -n "$SELECTED_WALLPAPER" ]; then
    FULL_WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED_WALLPAPER"

    # Initialize swww if it’s not running
    if ! pgrep -x "swww-daemon" >/dev/null; then
        echo "Starting swww daemon..."
        swww init || {
            echo "Failed to initialize swww"
            exit 1
        }
    fi

    # Set wallpaper using swww with fade transition
    swww img "$FULL_WALLPAPER_PATH" --transition-type "any" --transition-fps 60 --transition-duration 2 || {
        echo "Failed to set wallpaper with swww"
        exit 1
    }

    # Run wal to apply the theme
    wal -i "$FULL_WALLPAPER_PATH" # Set the new wallpaper with wal

    echo "Wallpaper changed to: $FULL_WALLPAPER_PATH"
else
    echo "No wallpaper selected."
fi
