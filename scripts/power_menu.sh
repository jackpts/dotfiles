#!/bin/bash

uptime="$(uptime -p | sed -e 's/up //g')"
theme="$HOME/.config/rofi/style.rasi"

shutdown=' Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend=' Suspend'
logout=' LogOut'

chosen=$(echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$logout" |
    rofi -dmenu -p "Uptime: $uptime" -mesg "Uptime: $uptime" -theme ${theme})

case "$chosen" in
$shutdown) systemctl poweroff ;;
$reboot) systemctl reboot ;;
$lock) $HOME/scripts/lock_with_matrix.sh ;;
$suspend) systemctl suspend ;;
$logout) hyprctl dispatch exit ;;
*) exit 1 ;;
esac
