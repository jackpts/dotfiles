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
if command -v checkupdates >/dev/null 2>&1; then
  updates_count=$(checkupdates 2>/dev/null | wc -l)
else
  # Fallback to pacman -Qu if checkupdates is not available
  if pacman -Qu >/dev/null 2>&1; then
    updates_count=$(pacman -Qu 2>/dev/null | wc -l)
  fi
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

# Build simple package list tooltip
tooltip=""
if [ "$total_updates" -gt 0 ]; then
  # Get all packages (official + AUR) up to 50 total
  all_packages=""
  
  # Add official repo packages
  if [ "$updates_count" -gt 0 ]; then
    if command -v checkupdates >/dev/null 2>&1; then
      official_pkgs=$(checkupdates 2>/dev/null | awk '{print $1}')
    else
      official_pkgs=$(pacman -Qu 2>/dev/null | awk '{print $1}')
    fi
    all_packages="$official_pkgs"
  fi
  
  # Add AUR packages
  if [ "$aur_count" -gt 0 ]; then
    if command -v paru >/dev/null 2>&1; then
      aur_pkgs=$(paru -Qua 2>/dev/null | awk '{print $1}')
    elif command -v yay >/dev/null 2>&1; then
      aur_pkgs=$(yay -Qua 2>/dev/null | awk '{print $1}')
    fi
    
    if [ -n "$all_packages" ] && [ -n "$aur_pkgs" ]; then
      all_packages="${all_packages}
${aur_pkgs}"
    elif [ -n "$aur_pkgs" ]; then
      all_packages="$aur_pkgs"
    fi
  fi
  
  # Take first 50 packages and add indentation
  tooltip=$(echo "$all_packages" | head -n 50 | sed 's/^/  /')
  
  # Add "..." if there are more than 50 total packages
  if [ "$total_updates" -gt 50 ]; then
    tooltip="${tooltip}
  ..."
  fi
else
  tooltip="System up to date"
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

# Escape for JSON
tooltip_escaped=$(printf '%s' "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$display_text" "$tooltip_escaped" "$class"
