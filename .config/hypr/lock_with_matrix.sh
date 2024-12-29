#!/bin/bash

run_matrix="kitty --start-as=fullscreen -e cmatrix -C green -u 10 -b"

# if ! [ -z (pgrep hyprlock)]; then
# screens=$(hyprctl -j monitors | jq length)
# for ((i = -1; i < $screens; i++)); do
# hyprctl dispatch focusmonitor $i
eval $run_matrix
hyprlock
kill -9 $(pgrep -f "$run_matrix") # pkill cmatrix
# done
# fi
