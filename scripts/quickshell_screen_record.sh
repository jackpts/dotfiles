#!/usr/bin/env bash
set -euo pipefail

BASE_SCRIPT="$HOME/dotfiles/scripts/screen_record.sh"

exec_detached() {
  # Run the base script detached via sway (preferred), fallback to setsid
  local cmd="$BASE_SCRIPT $*"
  if command -v swaymsg >/dev/null 2>&1; then
    if swaymsg -q exec -- "$cmd"; then
      exit 0
    fi
  fi
  setsid -f bash -lc "$cmd" >/dev/null 2>&1 || bash -lc "$cmd"
}

case "${1-}" in
  --toggle)
    exec_detached --toggle
    ;;
  --stop)
    "$BASE_SCRIPT" --stop
    ;;
  --fullscreen|--fullscreen-sound|--area|--area-sound|--window|--window-sound|--gif)
    exec_detached "$1"
    ;;
  *)
    # Status passthrough (Waybar-compatible JSON)
    "$BASE_SCRIPT"
    ;;
esac
