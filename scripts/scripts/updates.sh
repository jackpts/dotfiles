#!/bin/sh   
#
# requires pacman-contrib trizen
# modified by scorpii
# -----------------------------------------------------
threshhold_zero=-1
threshhold_green=0
threshhold_yellow=20
threshhold_red=100
# ----------------------------------------------------- 
# Calculate available updates pacman and aur (trizen)
# ----------------------------------------------------- 
if ! updates_arch=$(checkupdates 2> /dev/null | wc -l ); then
    updates_arch=0
fi
if ! updates_aur=$(trizen -Su --aur --quiet | wc -l); then
    updates_aur=0
fi
updates=$(("$updates_arch" + "$updates_aur"))
# ----------------------------------------------------- 
# Output in JSON format for Waybar Module custom-updates
# ----------------------------------------------------- 
css_class="zero"
if [ "$updates" -gt $threshhold_green ]; then
    css_class="green"
fi
if [ "$updates" -gt $threshhold_yellow ]; then
    css_class="yellow"
fi
if [ "$updates" -gt $threshhold_red ]; then
    css_class="red"
fi
if [ "$updates" -gt $threshhold_zero ]; then
    printf '{"text": "%s", "alt": "%s", "tooltip": "%s Updates", "class": "%s"}' "$updates" "$updates" "$updates" "$css_class"
else
    printf '{"text": "0", "alt": "0", "tooltip": "0 Updates", "class": "zero"}'
fi
