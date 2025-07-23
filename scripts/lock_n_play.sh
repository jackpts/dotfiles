#!/bin/bash

get_waybar_ipc_socket() {
    WAYBAR_PID=$(pgrep waybar)
    if [ -z "$WAYBAR_PID" ]; then
        echo "Error: Waybar is not running." >&2
        return 1
    fi
    echo "/tmp/waybar-ipc-${WAYBAR_PID}.sock"
}

get_active_monitor_resolution() {
    # Получаем информацию об активном мониторе в JSON, затем извлекаем ширину и высоту
    MONITOR_RESOLUTION=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width)x\(.height)"')

    if [ -z "$MONITOR_RESOLUTION" ]; then
        # echo "Error: Could not get active monitor resolution." >&2
        # return 1
        notify-send "Error" "Could not get monitor resolution!"
        echo "2560x1600"
    fi
    echo "$MONITOR_RESOLUTION"
}

WAYBAR_IPC_SOCKET=$(get_waybar_ipc_socket)

if [ -z "$WAYBAR_IPC_SOCKET" ]; then
    notify-send "Error" "Waybar IPC socket not found. Is Waybar running?"
    exit 1
fi

MONITOR_RESOLUTION=$(get_active_monitor_resolution)
echo '{"command":"layer", "layer":"overlay"}' | socat - "$WAYBAR_IPC_SOCKET"
sleep 0.2

VIDEO_FILE="/home/jacky/Pictures/walls/live-walls_from_motionbgs.com/clair-obscur.3840x2160.mp4"

mpv "$VIDEO_FILE" \
    --loop \
    --no-audio \
    --geometry="$MONITOR_RESOLUTION" \
    --no-terminal \
    --no-border \
    --input-ipc-server=/tmp/mpvlock-ipc \
    --speed=1.0 \
    --panscan=1.0 \
    --vo=wayland \
    --hwdec=auto \
    --log-file=/tmp/mpv.log \
    --msg-level=all=info \
    --ontop \
    --wayland-app-id=mpv-lock-screen \
    --wayland-configure-size-mode=maximize \
    --fullscreen \
    --layer=overlay \
    --gpu-api=opengl &
MPV_PID=$!

# sleep 1

swaylock \
    --color 00000000 \
    --key-hl-color 458588 \
    --bs-hl-color cc241d \
    --ring-color on \
    --text-color ebdbb2 \
    --line-color ebdbb2 \
    --inside-color 3c383600 \
    --font "Sans" \
    --font-size 20

# hyprlock

kill $MPV_PID 2>/dev/null
echo '{"command":"layer", "layer":"top"}' | socat - "$WAYBAR_IPC_SOCKET"

