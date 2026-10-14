#!/usr/bin/env bash
# voxtype-status.sh — status / control helper for jackbar VoxtypeIndicator
#
# Usage:
#   voxtype-status.sh follow   → stream Waybar-style JSON lines
#   voxtype-status.sh once     → single JSON line
#   voxtype-status.sh toggle   → voxtype record toggle
#   voxtype-status.sh config   → open voxtype-tui or setup hints

set -euo pipefail

missing_json() {
    printf '%s\n' '{"text":"󰚨","class":"missing","alt":"stopped","available":false,"tooltip":"Voxtype not installed\nparu -S voxtype-bin wtype\nvoxtype setup model && voxtype setup systemd"}'
}

have_voxtype() {
    command -v voxtype >/dev/null 2>&1
}

cmd_once() {
    if ! have_voxtype; then
        missing_json
        return 0
    fi
    # Prefer extended + nerd-font icons for jackbar
    if voxtype status --format json --extended --icon-theme nerd-font 2>/dev/null; then
        return 0
    fi
    if voxtype status --format json --extended 2>/dev/null; then
        return 0
    fi
    voxtype status --format json 2>/dev/null || missing_json
}

cmd_follow() {
    if ! have_voxtype; then
        missing_json
        # Keep process alive so SplitParser has a long-running source; repoll install state
        while true; do
            sleep 8
            if have_voxtype; then
                break
            fi
            missing_json
        done
    fi
    # Follow mode — instant updates via inotify on state file
    if voxtype status --follow --format json --extended --icon-theme nerd-font 2>/dev/null; then
        return 0
    fi
    if voxtype status --follow --format json --extended 2>/dev/null; then
        return 0
    fi
    if voxtype status --follow --format json 2>/dev/null; then
        return 0
    fi
    # Polling fallback
    while true; do
        cmd_once || true
        sleep 1
    done
}

cmd_toggle() {
    if ! have_voxtype; then
        notify-send -u normal -a "Voxtype" "Voxtype not installed" \
            "Install: paru -S voxtype-bin wtype"$'\n'"Then: voxtype setup model && voxtype setup systemd" || true
        exit 1
    fi
    voxtype record toggle
}

cmd_daemon_status() {
    if ! have_voxtype; then
        echo "missing"
        return 0
    fi
    if systemctl --user is-active --quiet voxtype 2>/dev/null; then
        echo "running"
        return 0
    fi
    # activating / failed / inactive
    local st
    st=$(systemctl --user is-active voxtype 2>/dev/null || true)
    case "$st" in
        active) echo "running" ;;
        activating) echo "starting" ;;
        *) echo "stopped" ;;
    esac
}

cmd_daemon_start() {
    if ! have_voxtype; then
        echo "missing"
        exit 1
    fi
    systemctl --user start voxtype 2>/dev/null || true
    # brief wait then report
    sleep 0.4
    cmd_daemon_status
}

cmd_daemon_stop() {
    if ! have_voxtype; then
        echo "missing"
        exit 1
    fi
    systemctl --user stop voxtype 2>/dev/null || true
    sleep 0.2
    cmd_daemon_status
}

cmd_daemon_toggle() {
    local st
    st=$(cmd_daemon_status)
    case "$st" in
        running|starting) cmd_daemon_stop ;;
        *) cmd_daemon_start ;;
    esac
}

cmd_config() {
    if command -v voxtype-tui >/dev/null 2>&1; then
        if command -v kitty >/dev/null 2>&1; then
            kitty --title voxtype-config voxtype-tui &
            disown || true
            exit 0
        fi
        voxtype-tui &
        disown || true
        exit 0
    fi
    if have_voxtype; then
        if command -v kitty >/dev/null 2>&1; then
            kitty --title voxtype-config bash -lc 'voxtype status --extended; echo; echo "Tip: paru -S voxtype-tui for the TUI configurator"; echo "Setup: voxtype setup model | voxtype setup systemd | voxtype setup waybar"; exec bash' &
            disown || true
            exit 0
        fi
        notify-send -u low -a "Voxtype" "Voxtype" "Daemon present. Install voxtype-tui for GUI/TUI config." || true
        exit 0
    fi
    notify-send -u normal -a "Voxtype" "Voxtype not installed" \
        "paru -S voxtype-bin wtype"$'\n'"optional: voxtype-tui"$'\n'"then: voxtype setup model && voxtype setup systemd" || true
}

case "${1:-follow}" in
    follow) cmd_follow ;;
    once) cmd_once ;;
    toggle) cmd_toggle ;;
    config) cmd_config ;;
    daemon)
        case "${2:-status}" in
            status) cmd_daemon_status ;;
            start) cmd_daemon_start ;;
            stop) cmd_daemon_stop ;;
            toggle) cmd_daemon_toggle ;;
            *)
                echo "usage: $0 daemon status|start|stop|toggle" >&2
                exit 2
                ;;
        esac
        ;;
    *)
        echo "usage: $0 follow|once|toggle|config|daemon ..." >&2
        exit 2
        ;;
esac
