#!/bin/bash

shutdown=' Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend=' Suspend'
logout=' LogOut'

# chosen=$(echo -e "Shutdown\nReboot\nLock\nSuspend\nHybernate\nLogOut" | rofi -dmenu -i -p "Power")
chosen=$(echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$logout" | rofi -dmenu -i -p "Power")

case "$chosen" in
$shutdown) systemctl poweroff ;;
$reboot) systemctl reboot ;;
$lock) swaylock ;;
$suspend) systemctl suspend ;;
# Hybernate) systemctl hybernate ;;
# LogOut) kill -1 -1 ;;
$logout) hyprctl dispatch exit ;;
*) exit 1 ;;
esac
