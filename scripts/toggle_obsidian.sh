#!/bin/bash
APP="obsidian"

cnt=$(swaymsg -t get_tree | jq '[.. | objects | select(.app_id != null) | select(.app_id | ascii_downcase == "'"$APP"'")] | length')

if [ "$cnt" -eq 0 ]; then
    "$APP" &
    exit 0
fi

focused=$(swaymsg -t get_tree | jq '[.. | objects | select(.focused == true and .app_id != null) | select(.app_id | ascii_downcase == "'"$APP"'")] | length')

if [ "$focused" -gt 0 ]; then
    swaymsg "[app_id=$APP] move scratchpad"
else
    swaymsg "[app_id=$APP] scratchpad show"
    swaymsg "[app_id=$APP] focus"
fi
