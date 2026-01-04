#!/bin/bash

# Check for pacman updates
pacman_updates=$(checkupdates 2>/dev/null | awk '{print $1}')
pacman_count=$(echo "$pacman_updates" | awk 'NF' | wc -l)

# Check for AUR updates
aur_updates=$(paru -Qua 2>/dev/null | awk '{print $1}')
aur_count=$(echo "$aur_updates" | wc -l)

total_updates=$((pacman_count + aur_count))
icon="⟳"

# Output JSON format for Quickshell
if [ "$total_updates" -gt 0 ]; then
    # Build tooltip with package lists
    tooltip_packages=""
    if [ "$pacman_count" -gt 0 ]; then
        tooltip_packages="$tooltip_packages\nPacman updates:\n$pacman_updates"
    fi
    if [ "$aur_count" -gt 0 ]; then
        if [ "$pacman_count" -gt 0 ]; then
            tooltip_packages="$tooltip_packages\n____________"
        fi
            tooltip_packages="$tooltip_packages\nAUR updates:\n$aur_updates"
    fi
    escaped_tooltip=$(echo "$tooltip_packages" | sed ':a;N;$!ba;s/\n/\\n/g')
    json_output=$(printf '{"text": "%s %s+%s", "tooltip": "There are %d update(s) available:%s", "class": "updates-available", "pacman": %d, "aur": %d}' "$icon" "$pacman_count" "$aur_count" "$total_updates" "$escaped_tooltip" "$pacman_count" "$aur_count")
else
    json_output=$(printf '{"text": "%s 0+0", "tooltip": "System is up to date", "class": "updates-none", "pacman": 0, "aur": 0}' "$icon")
fi

echo "$json_output"
