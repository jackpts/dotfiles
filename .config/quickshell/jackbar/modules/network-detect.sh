#!/usr/bin/env bash

route=$(ip route get 1.1.1.1 2>/dev/null)
route_dev=$(echo "$route" | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
route_ip=$(echo "$route" | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')
device_info=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null || echo)

# Find connected WiFi device
wifi_dev=$(echo "$device_info" | awk -F: '$2=="wifi" && $3 ~ /^connected/ {print $1; exit}')
# Find connected Ethernet device
eth_dev=$(echo "$device_info" | awk -F: '$2=="ethernet" && $3 ~ /^connected/ {print $1; exit}')

# Default to route device, type disconnected
dev="$route_dev"
typ=disc

# Prioritize WiFi over Ethernet
if [ -n "$wifi_dev" ]; then
    dev="$wifi_dev"
    typ=wifi
elif [[ "$dev" == wl* ]]; then
    typ=wifi
elif [ -n "$eth_dev" ] && [[ ! "$eth_dev" =~ ^(docker|br-|veth|tun|tap) ]]; then
    dev="$eth_dev"
    typ=eth
elif [[ "$dev" == en* || "$dev" == eth* ]] && [[ ! "$dev" =~ ^(docker|br-|veth|tun|tap) ]]; then
    typ=eth
fi

# Get IP address
ip=""
if [ -n "$dev" ]; then
    ip=$(ip -4 -o addr show dev "$dev" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
fi
if [ -z "$ip" ]; then
    ip="$route_ip"
fi

# Get gateway
gw=$(ip route show default dev "$dev" 2>/dev/null | awk 'NR==1 {print $3}')
if [ -z "$gw" ]; then
    gw=$(echo "$route" | awk '{for(i=1;i<=NF;i++) if($i=="via") {print $(i+1); exit}}')
fi

# Get WiFi specific info
ssid=""
sig=""
sigdbm=""
freq=""
wdev=""

if [ "$typ" == "wifi" ] && [ -n "$dev" ]; then
    wdev="$dev"
elif [ -n "$wifi_dev" ]; then
    wdev="$wifi_dev"
fi

# Exclude Docker/virtual interfaces
if [ -n "$wdev" ] && [[ "$wdev" =~ ^(docker|br-|veth|tun|tap) ]]; then
    wdev=""
fi

if [ -n "$wdev" ]; then
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2}' | head -n1)
    sig=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $3}' | head -n1)
    sigdbm=$(iw dev "$wdev" link 2>/dev/null | awk '/signal:/ {print $2}')
    freq=$(iw dev "$wdev" link 2>/dev/null | awk '/freq:/ {gsub(/\.0$/, "", $2); print $2}')
fi

# Get traffic statistics
rx=0
tx=0
if [ -n "$dev" ]; then
    rx=$(cat /sys/class/net/"$dev"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx=$(cat /sys/class/net/"$dev"/statistics/tx_bytes 2>/dev/null || echo 0)
fi

# Determine final kind
kind=disc
if [ -n "$dev" ] && [ -n "$ip" ] && [ "$typ" != disc ]; then
    kind="$typ"
fi

printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$kind" "$ssid" "$sig" "$sigdbm" "$freq" "$ip" "$dev" "$gw" "$rx:$tx"
