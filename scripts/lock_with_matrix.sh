#!/bin/bash

run_matrix="kitty --start-as=fullscreen -e sh -c 'sleep 0.2 && cmatrix -u 10 -b -s -C cyan'"

if ! (pgrep -x cmatrix >/dev/null); then
    eval $run_matrix
    hyprlock -c "$HOME/dotfiles/.config/hypr/hyprlock.conf"
    kill -9 $(pgrep -f "$run_matrix")
fi
