#!/bin/bash

# Get current keyboard layout
layout=$(gdbus call --session --dest org.gnome.desktop.input-sources \
    --object-path /org/gnome/desktop/input-sources \
    --method org.freedesktop.DBus.Properties.Get \
    org.gnome.desktop.input-sources mru-sources | grep -Po "'.*?'" | head -1 | tr -d "'" | awk -F'+' '{print $2}')

# Map layout codes to names
case $layout in
    us) echo '🇺🇸' ;;
    ru) echo '🇷🇺' ;;
    *) echo "$layout" ;;
esac
