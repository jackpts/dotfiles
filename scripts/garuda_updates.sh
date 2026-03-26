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
  # checkupdates may exit non-zero even when there are 0 updates; ignore its exit code
  updates_count=$(checkupdates 2>/dev/null | wc -l) || true
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

MAX_OFFICIAL_LINES=50

indent_lines() {
  sed 's/^/  /'
}

line_count() {
  if [ -z "$1" ]; then
    echo 0
  else
    printf '%s\n' "$1" | sed '/^$/d' | wc -l | tr -d ' '
  fi
}

build_separator() {
  local combined="$1"$'\n'"$2"
  local max_len=12
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local len=${#line}
    if (( len > max_len )); then
      max_len=$len
    fi
  done <<< "$combined"
  printf '%*s' "$max_len" '' | tr ' ' '-'
}

# Build package list tooltip with priority for AUR packages
tooltip=""
if [ "$total_updates" -gt 0 ]; then
  official_pkgs=""
  aur_pkgs=""

  if [ "$updates_count" -gt 0 ]; then
    if command -v checkupdates >/dev/null 2>&1; then
      official_pkgs=$(checkupdates 2>/dev/null | awk '{print $1}')
    else
      official_pkgs=$(pacman -Qu 2>/dev/null | awk '{print $1}')
    fi
  fi

  if [ "$aur_count" -gt 0 ]; then
    if command -v paru >/dev/null 2>&1; then
      aur_pkgs=$(paru -Qua 2>/dev/null | awk '{print $1}')
    elif command -v yay >/dev/null 2>&1; then
      aur_pkgs=$(yay -Qua 2>/dev/null | awk '{print $1}')
    fi
  fi

  official_section=""
  if [ -n "$official_pkgs" ]; then
    official_display=$(printf '%s\n' "$official_pkgs" | head -n $MAX_OFFICIAL_LINES)
    official_section=$(printf '%s\n' "$official_display" | indent_lines)
    official_total=$(line_count "$official_pkgs")
    if [ "$official_total" -gt $MAX_OFFICIAL_LINES ]; then
      official_section="${official_section}
  ..."
    fi
  fi

  aur_section=""
  if [ -n "$aur_pkgs" ]; then
    aur_section=$(printf '%s\n' "$aur_pkgs" | indent_lines)
  fi

  if [ -n "$official_section" ] && [ -n "$aur_section" ]; then
    separator=$(build_separator "$official_section" "$aur_section")
    tooltip="${official_section}
${separator}
${aur_section}"
  elif [ -n "$official_section" ]; then
    tooltip="$official_section"
  elif [ -n "$aur_section" ]; then
    tooltip="$aur_section"
  fi

  if [ -z "$tooltip" ]; then
    tooltip="System up to date"
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

# Format the output - always show the count
if [ "$total_updates" -gt 0 ]; then
  if [ "$aur_count" -gt 0 ] && [ "$updates_count" -gt 0 ]; then
    display_text="$updates_count+$aur_count $icon"
  else
    display_text="$total_updates $icon"
  fi
else
  display_text="0 $icon"
fi

# Escape for JSON
tooltip_escaped=$(printf '%s' "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$display_text" "$tooltip_escaped" "$class"
