#!/bin/bash

STATE_FILE="$HOME/.config/waybar/bluelight_state"

toggle_state() {
    if [ -f "$STATE_FILE" ]; then
        killall hyprsunset
        rm "$STATE_FILE"
        hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is OFF!"
    else
        hyprsunset &
        touch "$STATE_FILE"
        hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is ON!"
    fi
}

get_state() {
    if [ -f "$STATE_FILE" ]; then
        echo '{"text": "", "tooltip": "Blue Light Filter: ON", "class": "on"}'
    else
        echo '{"text": "", "tooltip": "Blue Light Filter: OFF", "class": "off"}'
    fi
}

case "$1" in
--toggle)
    toggle_state
    ;;
*)
    get_state
    ;;
esac
