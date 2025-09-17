#!/usr/bin/env bash
set -euo pipefail

# Output Waybar JSON for Ubuntu/Debian updates
# Fields: text, tooltip, class (optional)

# Check if apt is available
if ! command -v apt >/dev/null 2>&1; then
  echo '{"text":"N/A","tooltip":"apt not found"}'
  exit 0
fi

# Count upgradable packages quickly (no download)
updates_count=$(apt list --upgradable 2>/dev/null | sed '1d' | wc -l | tr -d ' ')

# Build tooltip with a brief list (first 10)
list=$(apt list --upgradable 2>/dev/null | sed '1d' | awk -F/ '{print $1}' | head -n 10 | paste -sd ', ' -)
if [ -z "$list" ]; then list="No updates"; fi

# Choose icon based on count
icon="󰚰"
class="ok"
if [ "$updates_count" -gt 0 ]; then
  class="updates"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$updates_count $icon" "$list" "$class"
