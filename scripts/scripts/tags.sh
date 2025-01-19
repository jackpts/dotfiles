#!/bin/bash

music_dir="/run/media/jacky/store/music/new2/"

find "$music_dir" -type f -name "*.mp3" | while read -r file; do
    filename=$(basename "$file" .mp3)

    current_title=$(id3v2 -l "$file" | grep "TIT2" | awk -F: '{print $2}' | xargs)

    if [ -z "$current_title" ]; then
        echo "Adding tags for file: $file"
        id3v2 -t "$filename" "$file"
    else
        echo "Tags already exists for file: $file"
    fi
done
