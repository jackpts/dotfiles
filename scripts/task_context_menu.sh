#!/usr/bin/env bash
set -euo pipefail

con_id="${1:?container id required}"
window_title="${2:-Window}"

if ! command -v swaymsg >/dev/null || ! command -v jq >/dev/null; then
    exit 1
fi

tree="$(swaymsg -t get_tree)"
current_ws="$(echo "$tree" | jq --argjson id "$con_id" '
    [.. | objects | select(.type == "workspace")
        | select((.. | objects | .id? == $id)) | .num][0]
')"

if [[ -z "$current_ws" || "$current_ws" == "null" ]]; then
    notify-send "Window menu" "Could not find workspace for window ${con_id}" 2>/dev/null || true
    exit 1
fi

menu=""
max_ws=5
for num in $(seq 1 "$max_ws"); do
    [[ "$num" == "$current_ws" ]] && continue
    menu+="Move to workspace ${num}"$'\n'
done

if [[ -z "$menu" ]]; then
    menu="(no other workspaces)"$'\n'
fi
menu+="Close window"$'\n'

prompt="$window_title (ws ${current_ws})"
if [[ -n "${ROFI_THEME:-}" && -f "$ROFI_THEME" ]]; then
    choice="$(echo -n "$menu" | rofi -dmenu -p "$prompt" -theme "$ROFI_THEME")" || exit 0
else
    choice="$(echo -n "$menu" | rofi -dmenu -p "$prompt")" || exit 0
fi

[[ -z "$choice" || "$choice" == "(no other workspaces)" ]] && exit 0

if [[ "$choice" == "Close window" ]]; then
    swaymsg "[con_id=${con_id}] kill"
elif [[ "$choice" =~ ^Move\ to\ workspace\ ([0-9]+)$ ]]; then
    swaymsg "[con_id=${con_id}] move container to workspace number ${BASH_REMATCH[1]}"
fi
