#!/bin/bash
CLASS="nvim"

cnt=$(swaymsg -t get_tree | jq '[.. | objects | select(.app_id != null) | select(.app_id == "'"$CLASS"'")] | length')

if [ "$cnt" -eq 0 ]; then
    kitty --class "$CLASS" nvim &
    exit 0
fi

focused=$(swaymsg -t get_tree | jq '[.. | objects | select(.focused == true and .app_id != null) | select(.app_id == "'"$CLASS"'")] | length')

if [ "$focused" -gt 0 ]; then
    swaymsg "[app_id=$CLASS] move scratchpad"
else
    swaymsg "[app_id=$CLASS] scratchpad show"
    swaymsg "[app_id=$CLASS] focus"
fi
