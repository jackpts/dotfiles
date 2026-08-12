#!/bin/bash
APP="obsidian"

win_id=$(swaymsg -t get_tree | jq -r --arg app "$APP" '
  [.. | objects
   | select(.pid != null)
   | select(
       (((.app_id // "") | ascii_downcase) | contains($app)) or
       (((.window_properties.class // "") | ascii_downcase) | contains($app))
     )
   | .id][0] // empty')

if [ -z "$win_id" ]; then
    "$APP" &
    exit 0
fi

focused=$(swaymsg -t get_tree | jq -r --arg app "$APP" '
  [.. | objects
   | select(.focused == true)
   | select(
       (((.app_id // "") | ascii_downcase) | contains($app)) or
       (((.window_properties.class // "") | ascii_downcase) | contains($app))
     )
  ] | length')

if [ "$focused" -gt 0 ]; then
    swaymsg "[con_id=$win_id] move scratchpad"
else
    swaymsg "[con_id=$win_id] scratchpad show"
    swaymsg "[con_id=$win_id] focus"
fi
