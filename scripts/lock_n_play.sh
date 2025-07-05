#!/bin/bash

VIDEO_FILE="/home/jacky/Pictures/walls/live-walls_from_motionbgs.com/cyberpunk/kda-akali-motorbike.1920x1080.mp4"

mpv "$VIDEO_FILE" \
    --loop \
    --no-audio \
    --fullscreen \
    --no-terminal \
    --input-ipc-server=/tmp/mpvlock-ipc \
    --speed=1.0 \
    --panscan=1.0 &
MPV_PID=$!

# sleep 0.5

swaylock \
    --color 00000020 \
    --key-hl-color 458588 \
    --bs-hl-color cc241d \
    --ring-color on \
    --text-color ebdbb2 \
    --line-color ebdbb2 \
    --inside-color 3c3836 \
    --font "Sans" \
    --font-size 20

kill $MPV_PID
