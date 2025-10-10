#!/usr/bin/env bash
set -euo pipefail

# Output Waybar JSON for Garuda Linux/Arch updates
# Fields: text, tooltip, class (optional)

# Check if pacman is available
if ! command -v pacman >/dev/null 2>&1; then
  echo '{"text":"N/A","tooltip":"pacman not found"}'
  exit 0
fi

# Count available updates (official repos + AUR if available)
updates_count=0
if pacman -Qu >/dev/null 2>&1; then
  updates_count=$(pacman -Qu 2>/dev/null | wc -l)
fi

# Add AUR updates if paru or yay is available
aur_count=0
if command -v paru >/dev/null 2>&1; then
  if paru -Qua >/dev/null 2>&1; then
    aur_count=$(paru -Qua 2>/dev/null | wc -l)
  fi
elif command -v yay >/dev/null 2>&1; then
  if yay -Qua >/dev/null 2>&1; then
    aur_count=$(yay -Qua 2>/dev/null | wc -l)
  fi
fi

total_updates=$((updates_count + aur_count))

# Build tooltip with a brief list (first 10)
list=""
if [ "$updates_count" -gt 0 ]; then
  list=$(pacman -Qu 2>/dev/null | awk '{print $1}' | head -n 8 | paste -sd ', ' -)
fi

# Add AUR packages to tooltip if available
if [ "$aur_count" -gt 0 ]; then
  aur_list=""
  if command -v paru >/dev/null 2>&1; then
    aur_list=$(paru -Qua 2>/dev/null | awk '{print $1}' | head -n 2 | paste -sd ', ' -)
  elif command -v yay >/dev/null 2>&1; then
    aur_list=$(yay -Qua 2>/dev/null | awk '{print $1}' | head -n 2 | paste -sd ', ' -)
  fi
  
  if [ -n "$list" ] && [ -n "$aur_list" ]; then
    list="$list, $aur_list"
  elif [ -n "$aur_list" ]; then
    list="$aur_list"
  fi
fi

if [ -z "$list" ]; then 
  list="System up to date"
fi

# Dragon icon for Garuda Linux updates (with background)
icon=" 󰚰"
class="ok"
if [ "$total_updates" -gt 0 ]; then
  class="updates"
fi

# Format the output
if [ "$total_updates" -gt 0 ]; then
  if [ "$aur_count" -gt 0 ] && [ "$updates_count" -gt 0 ]; then
    display_text="$updates_count+$aur_count $icon"
  else
    display_text="$total_updates $icon"
  fi
else
  display_text="$icon"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$display_text" "$list" "$class"
