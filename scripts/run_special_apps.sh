#!/bin/bash

# Define the time interval (HH:MM format)
START_TIME="10:00"
END_TIME="23:59"

# Get the current time in HH:MM format
CURRENT_TIME=$(date +"%H:%M")

# Function to compare times
compare_times() {
    local t1=$(date -d "$1" +%s)
    local t2=$(date -d "$2" +%s)
    [ $t1 -le $t2 ]
}

# Check if the current time is within the interval
if compare_times "$START_TIME" "$CURRENT_TIME" && compare_times "$CURRENT_TIME" "$END_TIME"; then
    # Array of special apps
    special_apps=("telegram-desktop" "viber")

    # Iterate over the array and run each app using hyprctl dispatch exec
    for app in "${special_apps[@]}"; do
        hyprctl dispatch exec "$app"
    done
else
    msg="Current time is outside the regular interval.\nSome apps will not be run."
    # echo $msg # for debug
    sleep 2 && notify-send -u normal -i dialog-information \
        "Hey, $(whoami)!" "$msg"
    sh $HOME/scripts/bluelight.sh --toggle
fi
