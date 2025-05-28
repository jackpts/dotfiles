#!/bin/bash

json_data=$("$HOME/scripts/weather.sh")

if [ -n "$json_data" ]; then
    weather=$(echo "$json_data" | jq -r '.text')
    echo "$weather"
else
    echo "No data"
fi
