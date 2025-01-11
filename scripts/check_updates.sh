#!/bin/bash

# Check if checkupdates command exists
if ! command -v checkupdates &>/dev/null; then
    echo '{"text": "Error", "tooltip": "checkupdates not found", "class": "updates-error"}'
    exit 1
fi

# Use checkupdates to count available updates
updates=$(checkupdates 2>/dev/null)
updatesCount=$(echo "$updates" | awk 'NF' | wc -l)

icon="⟳"

# Output JSON format for Waybar
if [ "$updatesCount" -gt 0 ]; then
    escaped_updates=$(echo "\n$updates" | sed ':a;N;$!ba;s/\n/\\n/g')
    json_output=$(printf '{"text": "%s", "tooltip": "There are %d update(s) available:%s", "class": "updates-available"}' "$icon $updatesCount" "$updatesCount" "$escaped_updates")
else
    json_output=$(printf '{"text": "%s ", "tooltip": "System is up to date", "class": "updates-none"}' "$icon")
fi

echo "$json_output"
