#!/bin/bash

# Get CPU temperature from hwmon6 (coretemp)
temp_raw=$(cat /sys/class/hwmon/hwmon6/temp1_input 2>/dev/null)

if [ -n "$temp_raw" ]; then
    # Convert from millidegrees to degrees Celsius
    temp_celsius=$((temp_raw / 1000))
    echo "CPU Temperature: ${temp_celsius}°C"
else
    echo "CPU Temperature: N/A"
fi