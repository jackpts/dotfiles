#!/bin/bash

toggle_state() {
    if pgrep -x "hyprsunset" >/dev/null; then
        killall hyprsunset
        hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is OFF!"
    else
        hyprsunset &
        hyprctl notify -1 3000 "rgb(ff1ea3)" "Blue Light Filter is ON!"
    fi
}

get_state() {
    if pgrep -x "hyprsunset" >/dev/null; then
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
