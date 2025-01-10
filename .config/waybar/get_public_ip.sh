#!/bin/bash

# Fetch the public IP address
PUBLIC_IP=$(curl -s http://ipinfo.io/ip)

# Output the public IP in a format that Waybar can use
echo "{\"public_ip\":\"$PUBLIC_IP\"}"
