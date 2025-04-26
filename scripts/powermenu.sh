#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi"
theme='powermenu'

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Options
shutdown=' '
reboot='󰑓 '
lock=' '
suspend='󰒲 '
logout='󰍃 '
yes=' '
no=' '

# Rofi CMD
rofi_cmd() {
    rofi -dmenu \
        -p "Uptime: $uptime" \
        -mesg "Uptime: $uptime" \
        -theme ${dir}/${theme}.rasi
}

# Confirmation CMD
confirm_cmd() {
    current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
    rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        -theme ${dir}/${theme}.rasi \
        -display-drv wayland &
    rofi_pid=$!
    hyprctl dispatch movetoworkspace $current_workspace,pid:$rofi_pid
}

# Pass variables to rofi dmenu
run_rofi() {
    echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
$shutdown)
    systemctl poweroff
    ;;
$reboot)
    systemctl reboot
    ;;
$lock)
    # $HOME/scripts/lock_with_matrix.sh
    mpvlock
    ;;
$suspend)
    mpc -q pause
    amixer set Master mute
    systemctl suspend
    # $HOME/scripts/lock_with_matrix.sh
    mpvlock
    ;;
$logout)
    hyprctl dispatch exit
    ;;
esac
