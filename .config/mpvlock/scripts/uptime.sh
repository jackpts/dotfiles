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
printf "System Uptime:\n"
printf "%s\n" "$uptime_info"

# Optional: Display additional details like load average
# load_avg=$(uptime -p | awk '{print "Load Average:", $1, $2, $3}')
# printf "%s\n" "$load_avg"

exit 0
