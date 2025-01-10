#!/bin/bash

free_space=$(df -h /home | awk 'NR==2 {print $4}' | sed 's/G//')

if [ "$free_space" -lt 10 ]; then
    output=$(printf '{"text": "%s", "class": "exceed"}' "  $free_space Gb")
else
    output=$(printf '{"text": "%s", "class": "default"}' "  $free_space Gb")
fi

echo "$output"
