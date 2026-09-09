#!/bin/bash
# Save and restore wallpaper for Sway

WALLPAPER_SAVE="$HOME/.config/sway/wallpaper.conf"

# Save wallpaper path
save_wallpaper() {
    local path="$1"
    mkdir -p "$(dirname "$WALLPAPER_SAVE")"
    echo "wallpaper=\"$path\"" > "$WALLPAPER_SAVE"
}

# Load wallpaper path
load_wallpaper() {
    if [[ -f "$WALLPAPER_SAVE" ]]; then
        grep '^wallpaper=' "$WALLPAPER_SAVE" | cut -d'=' -f2 | tr -d '"'
    fi
}

# Restore wallpaper on Sway startup
restore_wallpaper() {
    local path
    path=$(load_wallpaper)

    if [[ -n "$path" && -f "$path" ]]; then
        # Wait for swaymsg to be ready
        for i in {1..10}; do
            if swaymsg -t get_outputs >/dev/null 2>&1; then
                swaymsg "output * bg \"$path\" fill"
                return 0
            fi
            sleep 1
        done
        # Final attempt even if check failed
        swaymsg "output * bg \"$path\" fill"
    fi
}

# Handle arguments
if [[ "$1" == "--restore" ]]; then
    restore_wallpaper
elif [[ -n "$1" ]]; then
    save_wallpaper "$1"
    echo "Saved: $1"
fi
