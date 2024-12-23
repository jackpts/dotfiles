#!/bin/bash

chosen=$(echo -e "Shutdown\nReboot\nLock" | rofi -dmenu -i -p "Power")

case "$chosen" in
  Shutdown) systemctl poweroff ;;
  Reboot) systemctl reboot ;;
  Lock) swaylock ;;
  Suspend) systemctl suspend ;;
  Hybernate) systemctl hybernate ;;
  Log Out) kill -1 -1 ;;
*) exit 1 ;;
esac
