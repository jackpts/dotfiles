#!/bin/bash

# Get public IP address for waybar
# Returns JSON format expected by waybar

get_public_ip() {
    # Try different services in order of preference
    local services=(
        "https://ifconfig.me"
        "https://icanhazip.com"
        "https://checkip.amazonaws.com"
        "https://ipinfo.io/ip"
    )
    
    for service in "${services[@]}"; do
        local ip=$(timeout 10 curl -s "$service" 2>/dev/null | tr -d '\n\r')
        
        # Validate IP format (basic check)
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    # If all services fail
    echo "N/A"
    return 1
}

# Get the public IP
public_ip=$(get_public_ip)

# Return JSON format for waybar
if [ "$public_ip" = "N/A" ]; then
    echo "{\"text\":\"󰖪 Offline\", \"tooltip\":\"No internet connection\", \"class\":\"disconnected\"}"
else
    echo "{\"text\":\"🌐 $public_ip\", \"tooltip\":\"Public IP: $public_ip\", \"class\":\"connected\"}"
fi
