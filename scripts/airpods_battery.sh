#!/bin/bash
# Get AirPods battery by monitoring Bluetooth and checking librepods window
# Usage: airpods_battery.sh <MAC_ADDRESS>

MAC="$1"
if [ -z "$MAC" ]; then
    exit 1
fi

# Method 1: Check if librepods is running and get battery from its window title
if pgrep -x librepods >/dev/null 2>&1; then
    # Try to get battery from librepods window using xdotool or wmctrl
    if command -v xdotool >/dev/null 2>&1; then
        WINDOW_INFO=$(xdotool search --name "LibrePods" 2>/dev/null | head -1)
        if [ -n "$WINDOW_INFO" ]; then
            TITLE=$(xdotool getwindowname "$WINDOW_INFO" 2>/dev/null)
            # Try to extract battery percentage from title (if shown)
            BATT=$(echo "$TITLE" | grep -oP '\d+%' | head -1 | tr -d '%')
            if [ -n "$BATT" ] && [ "$BATT" -gt 0 ] 2>/dev/null; then
                echo "$BATT"
                exit 0
            fi
        fi
    fi
fi

# Method 2: Check sysfs for any battery device
for sysfs in /sys/class/power_supply/*/; do
    if [ -f "${sysfs}device/address" ]; then
        ADDR=$(cat "${sysfs}device/address" 2>/dev/null | tr '[:lower:]' '[:upper:]')
        if [ "$ADDR" = "$MAC" ] && [ -f "${sysfs}capacity" ]; then
            BATT=$(cat "${sysfs}capacity" 2>/dev/null)
            if [ -n "$BATT" ] && [ "$BATT" -gt 0 ] 2>/dev/null; then
                echo "$BATT"
                exit 0
            fi
        fi
    fi
done

# Method 3: Parse D-Bus Battery1 interface
DBUS_PATH="/org/bluez/hci0/dev_${MAC//:/_}"
BATT=$(gdbus call --system --dest org.bluez --object-path "$DBUS_PATH" \
    --method org.freedesktop.DBus.Properties.Get org.bluez.Battery1 Percentage 2>/dev/null | \
    grep -oP '\d+' | head -1)

if [ -n "$BATT" ] && [ "$BATT" -gt 0 ] 2>/dev/null; then
    echo "$BATT"
    exit 0
fi

# No battery found
exit 1
