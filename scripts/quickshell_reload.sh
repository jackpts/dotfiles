#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/dotfiles/.config/quickshell/jackbar"
lock_file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-jackbar.reload.lock"

exec 9>"$lock_file"
if ! flock -n 9; then
    echo "quickshell reload already in progress" >&2
    exit 1
fi

qs_running() {
    quickshell list -p "$cfg" 2>/dev/null | grep -q '^Instance '
}

for _ in $(seq 1 50); do
    qs_running || break
    quickshell kill -p "$cfg" 2>/dev/null || true
    sleep 0.2
done

if qs_running; then
    echo "failed to stop existing quickshell instance" >&2
    exit 1
fi

sleep 1

if qs_running; then
    echo "quickshell already running; skip start" >&2
    exit 0
fi

exec quickshell -d -n -p "$cfg" "$@"
