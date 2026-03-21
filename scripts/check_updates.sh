#!/usr/bin/env bash
set -euo pipefail

# Check for pacman updates
pacman_updates=$(checkupdates 2>/dev/null | awk '{print $1}' || true)
pacman_count=$(echo "$pacman_updates" | awk 'NF' | wc -l)

# Check for AUR updates
aur_updates=$(paru -Qua 2>/dev/null | awk '{print $1}' || true)
aur_count=$(echo "$aur_updates" | wc -l)

total_updates=$((pacman_count + aur_count))
icon="⟳"

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

  if [ "$pacman_count" -gt 0 ]; then
    official_pkgs=$(checkupdates 2>/dev/null | awk '{print $1}' || true)
  fi

  if [ "$aur_count" -gt 0 ]; then
    aur_pkgs=$(paru -Qua 2>/dev/null | awk '{print $1}' || true)
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

icon=" 󰚰"
class="ok"
if [ "$total_updates" -gt 0 ]; then
  class="updates"
fi

# Format the output - always show the count
if [ "$total_updates" -gt 0 ]; then
  if [ "$aur_count" -gt 0 ] && [ "$pacman_count" -gt 0 ]; then
    display_text="$pacman_count+$aur_count $icon"
  else
    display_text="$total_updates $icon"
  fi
else
  display_text="0 $icon"
fi

# Escape for JSON
tooltip_escaped=$(printf '%s' "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$display_text" "$tooltip_escaped" "$class"
