#!/bin/bash

# Define icon for connected devices and disconnected/no devices
CONNECTED_ICON=""
DISCONNECTED_ICON="󰂲"
BATTERY_ICON=" "

# Get a list of connected Bluetooth device MAC addresses only
devices_macs=$(bluetoothctl devices Connected | grep -oP 'Device\s+([0-9A-F:]{17})' | awk '{print $2}' | sort -u)

waybar_output_parts=()
tooltip_device_lines=()

if [ -z "$devices_macs" ]; then
    echo "{\"text\": \"${DISCONNECTED_ICON}\", \"tooltip\": \"No Bluetooth devices connected or Bluetooth is off\"}"
    exit 0
fi

controller_alias=$(bluetoothctl show | grep 'Alias:' | awk '{print substr($0, index($0,$2))}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # Trim
num_connections=0

for device_mac in $devices_macs; do
    # Only process if MAC address is valid
    if [[ "$device_mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
        num_connections=$((num_connections + 1))

        device_alias=$(bluetoothctl info "$device_mac" | grep 'Alias:' | awk '{print substr($0, index($0,$2))}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # Trim whitespace
        if [ -z "$device_alias" ]; then
            device_alias="Unknown Device ($device_mac)"
        fi

        battery_percentage_raw=$(bluetoothctl info "$device_mac" | awk -F '[()]' '/Battery Percentage:/ {print $2}' | grep -oP '\d+')

        current_battery_status=""
        current_tooltip_line=""

        if [ -n "$battery_percentage_raw" ]; then
            current_battery_status="${battery_percentage_raw}%"
            current_tooltip_line="${device_alias}\t${BATTERY_ICON} ${battery_percentage_raw}%"
        else
            current_battery_status="N/A"
            current_tooltip_line="${device_alias}"
        fi

        waybar_output_parts+=("${current_battery_status}")
        tooltip_device_lines+=("${current_tooltip_line}")
    fi
done

main_display_text=$(
    IFS=" | "
    echo "${waybar_output_parts[*]}"
)
if [ -z "$main_display_text" ]; then
    main_display_text="No devices"
fi

tooltip_header="${controller_alias}\n${num_connections} connected\n"
tooltip_body=$(
    IFS=$'\n'
    echo "${tooltip_device_lines[*]}"
)

combined_tooltip_text=$(printf "%b\n%b" "$tooltip_header" "$tooltip_body" | awk '!NF {p++; next} {if(p) {for(i=0; i<p; i++) print ""; p=0}; print}')

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed. Please install it with 'sudo pacman -S jq'." >&2
    echo "{\"text\": \"${DISCONNECTED_ICON}\", \"tooltip\": \"jq not installed\"}"
    exit 1
fi

json_output=$(jq -n \
    --arg text "${CONNECTED_ICON} ${main_display_text}" \
    --arg tooltip "${combined_tooltip_text}" \
    '{text: $text, tooltip: $tooltip}')

# Remove potential newlines from the final output for cleaner JSON
json_output=$(echo "$json_output" | tr -d '\n\r')

echo "$json_output"
