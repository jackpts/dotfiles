#!/bin/bash

# Get CPU usage (rounded to integer)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{printf "%.0f", $1}')

# Get CPU temperature (using hwmon4 as configured in waybar)
temp_raw=$(cat /sys/class/hwmon/hwmon4/temp1_input 2>/dev/null)

if [ -n "$temp_raw" ]; then
    temp_celsius=$((temp_raw / 1000))
    tooltip="CPU Temperature: ${temp_celsius}°C"
else
    tooltip="CPU Temperature: N/A"
fi

# Output JSON format for waybar with original CPU icon and proper spacing
echo "{\"text\":\"  ${cpu_usage}%\",\"tooltip\":\"${tooltip}\"}"
