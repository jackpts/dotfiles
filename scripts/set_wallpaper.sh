#!/bin/bash
# Helper script to set wallpaper with proper escaping

path="$1"
mode="${2:-fill}"

# Escape parentheses, spaces, and commas for swaymsg
escaped=$(printf '%s' "$path" | sed 's/[() ,]/\\&/g')

swaymsg "output * bg $escaped $mode"
