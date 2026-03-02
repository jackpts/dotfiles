#!/usr/bin/env bash
set -euo pipefail

KITTY_BIN=${KITTY_BIN:-kitty}
LOCK_APP_ID=${LOCK_APP_ID:-lockaquarium}
LOCK_CMD=${LOCK_CMD:-hyprlock -c "$HOME/dotfiles/.config/hypr/hyprlock.conf"}
SWAYMSG_BIN=${SWAYMSG_BIN:-swaymsg}
LOCK_GUARD_FILE=${LOCK_GUARD_FILE:-/tmp/asciiquarium_lock_running}

# Prevent multiple instances (e.g., from key repeat)
exec 9>"$LOCK_GUARD_FILE"
if ! flock -n 9; then
    exit 0
fi
cleanup_guard() {
    rm -f "$LOCK_GUARD_FILE"
}
trap cleanup_guard EXIT

run_lock() {
    eval "$LOCK_CMD"
}

if ! command -v "$KITTY_BIN" >/dev/null 2>&1; then
    notify-send "Aquarium lock" "kitty not found, falling back to lock screen" >/dev/null 2>&1 || true
    run_lock
    exit 0
fi

"$KITTY_BIN" --class "$LOCK_APP_ID" --title "ASCII Aquarium" bash -lc 'set -euo pipefail

cleanup() {
    stty sane 2>/dev/null || true
    if [ -n "${AQUA_PID:-}" ]; then
        kill "$AQUA_PID" >/dev/null 2>&1 || true
        wait "$AQUA_PID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

if ! command -v asciiquarium >/dev/null 2>&1; then
    echo "asciiquarium is not installed."
    echo "Press any key to continue to the lock screen..."
    read -rsn1
    exit 0
fi

stty -echo -icanon min 1 time 0
asciiquarium &
AQUA_PID=$!
read -rsn1
kill "$AQUA_PID" >/dev/null 2>&1 || true
wait "$AQUA_PID" >/dev/null 2>&1 || true
' &
KITTY_PID=$!

# Give kitty a moment to map, then enforce fullscreen covering the panel
sleep 0.2
"$SWAYMSG_BIN" "[app_id=$LOCK_APP_ID] focus" >/dev/null 2>&1 || true
"$SWAYMSG_BIN" "[app_id=$LOCK_APP_ID] fullscreen enable global" >/dev/null 2>&1 || true

wait "$KITTY_PID"

run_lock
