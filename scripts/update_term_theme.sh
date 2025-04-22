#!/bin/bash

if ! command -v wal &>/dev/null; then
    echo "Error: pywal is not installed!"
    exit 1
fi

config_file="$HOME/.config/waypaper/config.ini"

wallpaper_path=$(grep '^wallpaper =' "$config_file" | cut -d '=' -f 2 | tr -d ' ' | tr -d '"')
wallpaper_path=$(eval echo "$wallpaper_path")

if [ -n "$wallpaper_path" ]; then
    wal -i "$wallpaper_path"
else
    echo "Cannot get the current wallpaper path!"
fi
