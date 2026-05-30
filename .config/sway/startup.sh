#!/bin/sh
set -eu

# This file is used by ~/.local/share/wayland-sessions/sway.desktop.
# Fish config is not sourced by display managers, so load compositor vars here.
env_file="${XDG_CONFIG_HOME:-$HOME/.config}/sway/env"
if [ -r "$env_file" ]; then
    set -a
    . "$env_file"
    set +a
fi

export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-sway}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-sway}"

if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session -- sway --unsupported-gpu "$@"
fi

exec sway --unsupported-gpu "$@"
