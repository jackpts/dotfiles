#!/bin/bash

# Use checkupdates to count available updates
updates=$(checkupdates | awk {'print $1'})
updatesCount=$(checkupdates 2>/dev/null | wc -l)

# Define the icon (use an appropriate icon that you have available)
icon="⟳" # Вы можете заменить этот символ на любой другой, например, из Font Awesome

# Output JSON format for Waybar
if [ "$updatesCount" -gt 0 ]; then
    # echo "{\"text\": \"$icon $updatesCount\", \"tooltip\": \"There are $updatesCount updates available:\n$updates\", \"class\": \"updates-available\"}"
    echo "{\"text\": \"$icon $updatesCount\", \"tooltip\": \"There are $updatesCount updates available\", \"class\": \"updates-available\"}"
else
    echo "{\"text\": \"$icon \", \"tooltip\": \"System is up to date\", \"class\": \"updates-none\"}"
fi
