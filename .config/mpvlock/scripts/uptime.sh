#!/bin/bash

# Check if the "awk" and "bc" commands exist and are executable
if ! command -v awk &>/dev/null || ! command -v bc &>/dev/null; then
    echo "Error: The 'awk' and/or 'bc' commands could not be found."
    exit 1
fi

# Get system uptime information in seconds
uptime_seconds=$(awk '{print int($1)}' /proc/uptime)

# Calculate hours and minutes using bc for integer division
hours=$((uptime_seconds/3600))
minutes=$(((uptime_seconds%3600)/60))

# Format the time as "HH:MM"
formatted_time=$(printf "%02d:%02d\n" $hours $minutes)

# Print the uptime with a formatted message
printf "Uptime: "
printf "%s\n" "$formatted_time"

exit 0
