#!/bin/bash

chosen=$(echo -e "Shutdown\nReboot\nLock\nSuspend\nHybernate\nLogOut" | rofi -dmenu -i -p "Power")

case "$chosen" in
Shutdown) systemctl poweroff ;;
Reboot) systemctl reboot ;;
Lock) swaylock ;;
Suspend) systemctl suspend ;;
Hybernate) systemctl hybernate ;;
# LogOut) kill -1 -1 ;;
LogOut) hyprctl dispatch exit ;;
*) exit 1 ;;
esac
