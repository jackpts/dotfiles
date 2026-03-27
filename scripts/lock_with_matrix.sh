#!/bin/bash

# Run cmatrix in kitty fullscreen
kitty --start-as=fullscreen -e sh -c 'cmatrix -u 10 -b -s -C cyan' &
MATRIX_PID=$!

# Wait a moment for cmatrix to start
sleep 0.3

# Lock the screen
hyprlock -c "$HOME/dotfiles/.config/hypr/hyprlock.conf"

# Kill cmatrix after unlock
kill $MATRIX_PID 2>/dev/null
wait $MATRIX_PID 2>/dev/null
