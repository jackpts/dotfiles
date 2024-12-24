#!/bin/bash

# Use checkupdates to count available updates
updates=$(checkupdates 2>/dev/null | wc -l)

# Define the icon (use an appropriate icon that you have available)
icon="⟳" # Вы можете заменить этот символ на любой другой, например, из Font Awesome

# Output JSON format for Waybar
if [ "$updates" -gt 0 ]; then
  echo "{\"text\": \"$icon $updates updates\", \"tooltip\": \"There are $updates updates available\", \"class\": \"updates-available\"}"
else
  echo "{\"text\": \"$icon No updates\", \"tooltip\": \"System is up to date\", \"class\": \"updates-none\"}"
fi
