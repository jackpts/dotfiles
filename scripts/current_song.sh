#!/bin/bash
# Fetch the current song title from ncmpcpp
# current_song=$(ncmpcpp --current-song | awk -F ' - ' '{print $2}')
current_song=$(mpc | head -n1)
echo "$current_song"
