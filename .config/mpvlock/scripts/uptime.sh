#!/bin/bash

# Check if the "uptime" command exists and is executable
if ! command -v uptime &>/dev/null; then
    echo "Error: The 'uptime' command could not be found."
    exit 1
fi

# Get system uptime information
# uptime_info=$(uptime)
uptime_info=$(uptime -p | sed -e 's/up //g')

# Print the uptime with a formatted message
printf "System Uptime: "
printf "%s\n" "$uptime_info"

exit 0
