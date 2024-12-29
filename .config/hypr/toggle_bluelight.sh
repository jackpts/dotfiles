#!/bin/bash

STATE_FILE="$HOME/.config/waybar/bluelight_state"

if [ -f "$STATE_FILE" ]; then
    killall hyprsunset
    rm "$STATE_FILE"
    hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is OFF!"
else
    hyprsunset &
    touch "$STATE_FILE"
    hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is ON!"
fi
