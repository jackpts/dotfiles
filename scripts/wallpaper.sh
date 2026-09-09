#!/bin/bash
# Wallpaper selector with visual thumbnail previews using FZF and Chafa

WALLPAPER_DIR="$HOME/Pictures/walls"
LAST_SELECTED_FILE="$HOME/.config/sway/wallpaper_last"
SET_WALLPAPER="$HOME/dotfiles/scripts/set_wallpaper.sh"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

mapfile -t IMAGES < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.webp" \) | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Get last selected image
LAST_SELECTED=""
if [[ -f "$LAST_SELECTED_FILE" ]]; then
    LAST_SELECTED=$(cat "$LAST_SELECTED_FILE")
fi

# Main loop - keeps running until user quits
while true; do
    SELECTED=$(printf '%s\n' "${IMAGES[@]}" | fzf \
        --preview 'chafa --size 80x40 {}' \
        --preview-window 'right:70%' \
        --layout=reverse \
        --border \
        --prompt='🖼️  Select wallpaper: ' \
        --header='↑/↓ navigate | Enter: set+quit | Ctrl-O: fill | Ctrl-R: fit | Ctrl-Q: quit' \
        --bind "ctrl-o:execute($SET_WALLPAPER '{}' fill)+abort" \
        --bind "ctrl-r:execute($SET_WALLPAPER '{}' fit)+abort" \
        --bind 'ctrl-q:abort' \
        --info='inline' \
        --height='90%' \
        --preview-label='Preview'
    )

    if [ -n "$SELECTED" ]; then
        $SET_WALLPAPER "$SELECTED" fill
        "$HOME/dotfiles/scripts/wallpaper_save.sh" "$SELECTED"
        echo "$SELECTED" > "$LAST_SELECTED_FILE"
        echo "✓ Wallpaper set: $(basename "$SELECTED")"
    else
        echo "Cancelled"
        break
    fi
done
