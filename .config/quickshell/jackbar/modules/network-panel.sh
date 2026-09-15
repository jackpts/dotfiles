#!/usr/bin/env bash
# network-panel.sh — nmcli helpers for jackbar NetworkPanel
#
# Commands:
#   wifi-list [rescan]     tab-separated: inuse ssid signal freq security saved bssid
#   wifi-connect <ssid> <saved> <security> [bssid]
#                          password on stdin when saved!=1 and network is secured
#   wifi-radio get|on|off
#   dns-get                dhcp|cloudflare|google|custom|<servers>
#   dns-set dhcp|cloudflare|google|custom [servers...]
#   ping-once              rttMs|lossPct
#   band-get / band-set 0|1

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/jackbar"
BAND_FILE="$CACHE_DIR/wifi-5ghz"

is_ignored_dev() {
    case "${1:-}" in
        lo|docker*|br-*|veth*|virbr*|lxcbr*|tun*|tap*|wg*|tailscale*) return 0 ;;
    esac
    return 1
}

active_conn() {
    local name typ dev
    local wifi="" eth=""
    while IFS=: read -r name typ dev; do
        [ -n "$name" ] || continue
        is_ignored_dev "$dev" && continue
        case "$typ" in
            802-11-wireless|wifi)
                [ -z "$wifi" ] && wifi="$name|$dev"
                ;;
            802-3-ethernet|ethernet)
                [ -z "$eth" ] && eth="$name|$dev"
                ;;
        esac
    done < <(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null)
    if [ -n "$wifi" ]; then
        printf '%s\n' "$wifi"
    elif [ -n "$eth" ]; then
        printf '%s\n' "$eth"
    fi
}

cmd_wifi_list() {
    local rescan="no"
    [ "${1:-}" = "rescan" ] && rescan="yes"

    python3 - "$rescan" <<'PY'
import subprocess, sys

rescan = sys.argv[1] if len(sys.argv) > 1 else "no"

def split_terse(line):
    parts, buf, esc = [], [], False
    for ch in line:
        if esc:
            buf.append(ch)
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    parts.append("".join(buf))
    return parts

def esc_field(s):
    return (s or "").replace("\\", "\\\\").replace("\t", " ").replace("\n", " ").replace("\r", "")

saved = set()
try:
    out = subprocess.check_output(
        ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"],
        text=True, stderr=subprocess.DEVNULL,
    )
    for line in out.splitlines():
        parts = split_terse(line)
        if len(parts) >= 2 and parts[1] in ("802-11-wireless", "wifi"):
            saved.add(parts[0])
except Exception:
    pass

try:
    out = subprocess.check_output(
        ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,FREQ,SECURITY,BSSID",
         "device", "wifi", "list", "--rescan", rescan],
        text=True, stderr=subprocess.DEVNULL,
    )
except Exception:
    sys.exit(0)

seen = set()
for line in out.splitlines():
    if not line.strip():
        continue
    parts = split_terse(line)
    if len(parts) < 6:
        continue
    in_use, ssid, signal, freq, security, bssid = parts[:6]
    ssid = ssid.strip()
    if not ssid or ssid == "--":
        continue
    freq_n = "".join(ch for ch in freq if ch.isdigit())
    key = (ssid, bssid)
    if key in seen:
        continue
    seen.add(key)
    is_saved = "1" if ssid in saved else "0"
    in_flag = "1" if in_use.strip() == "*" else "0"
    sec = security.strip() if security.strip() and security.strip() != "--" else ""
    print("\t".join([
        in_flag,
        esc_field(ssid),
        esc_field(signal.strip()),
        esc_field(freq_n),
        esc_field(sec),
        is_saved,
        esc_field(bssid),
    ]))
PY
}

cmd_wifi_connect() {
    local ssid="${1:-}"
    local saved="${2:-0}"
    local security="${3:-}"
    local bssid="${4:-}"
    if [ -z "$ssid" ]; then
        echo "missing ssid" >&2
        exit 2
    fi

    if [ "$saved" = "1" ]; then
        if nmcli -w 25 connection up id "$ssid" >/dev/null 2>&1; then
            exit 0
        fi
        # Saved profile name may differ; fall through to wifi connect.
    fi

    local pass=""
    if [ -n "$security" ]; then
        IFS= read -r pass || true
    fi

    local args=(nmcli -w 25 device wifi connect "$ssid")
    if [ -n "$bssid" ]; then
        args+=(bssid "$bssid")
    fi
    if [ -n "$security" ]; then
        if [ -z "$pass" ]; then
            echo "password required" >&2
            exit 2
        fi
        args+=(password "$pass")
    fi
    "${args[@]}"
}

cmd_wifi_radio() {
    case "${1:-get}" in
        get)
            if nmcli -t radio wifi 2>/dev/null | grep -qi '^enabled'; then
                echo "on"
            else
                echo "off"
            fi
            ;;
        on)
            nmcli radio wifi on
            cmd_wifi_radio get
            ;;
        off)
            nmcli radio wifi off
            cmd_wifi_radio get
            ;;
        *) echo "usage: wifi-radio get|on|off" >&2; exit 2 ;;
    esac
}

cmd_dns_get() {
    local pair name iface method dns ignore
    pair=$(active_conn)
    if [ -z "$pair" ]; then
        echo "dhcp"
        return
    fi
    name="${pair%%|*}"
    method=$(nmcli -t -f ipv4.method connection show "$name" 2>/dev/null | cut -d: -f2)
    dns=$(nmcli -t -f ipv4.dns connection show "$name" 2>/dev/null | cut -d: -f2- | tr ',' ' ' | xargs)
    ignore=$(nmcli -t -f ipv4.ignore-auto-dns connection show "$name" 2>/dev/null | cut -d: -f2)
    dns=${dns:-}
    ignore=${ignore:-no}

    if [ "$ignore" != "yes" ] && [ -z "$dns" ]; then
        echo "dhcp"
        return
    fi
    case " $dns " in
        *" 1.1.1.1 "*|*" 1.0.0.1 "*)
            echo "cloudflare"
            return
            ;;
        *" 8.8.8.8 "*|*" 8.8.4.4 "*)
            echo "google"
            return
            ;;
    esac
    if [ -n "$dns" ]; then
        printf 'custom|%s\n' "$dns"
    else
        echo "dhcp"
    fi
}

cmd_dns_set() {
    local mode="${1:-dhcp}"
    shift || true
    local pair name iface servers=""
    pair=$(active_conn)
    if [ -z "$pair" ]; then
        echo "no active connection" >&2
        exit 1
    fi
    name="${pair%%|*}"
    iface="${pair##*|}"

    case "$mode" in
        dhcp)
            nmcli connection modify "$name" ipv4.ignore-auto-dns no ipv4.dns ""
            ;;
        cloudflare)
            nmcli connection modify "$name" ipv4.ignore-auto-dns yes ipv4.dns "1.1.1.1 1.0.0.1"
            ;;
        google)
            nmcli connection modify "$name" ipv4.ignore-auto-dns yes ipv4.dns "8.8.8.8 8.8.4.4"
            ;;
        custom)
            servers=$(printf '%s ' "$@" | tr ',;' ' ' | xargs)
            if [ -z "$servers" ]; then
                echo "custom dns requires servers" >&2
                exit 2
            fi
            nmcli connection modify "$name" ipv4.ignore-auto-dns yes ipv4.dns "$servers"
            ;;
        *)
            echo "usage: dns-set dhcp|cloudflare|google|custom [servers]" >&2
            exit 2
            ;;
    esac

    if [ -n "$iface" ] && [ "$iface" != "--" ]; then
        nmcli device reapply "$iface" >/dev/null 2>&1 || nmcli -w 20 connection up "$name" >/dev/null
    else
        nmcli -w 20 connection up "$name" >/dev/null
    fi
    cmd_dns_get
}

cmd_ping_once() {
    local out rtt loss
    out=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null || true)
    rtt=$(printf '%s\n' "$out" | awk -F'=' '/time=/{print $NF}' | awk '{print $1}' | tail -n1)
    loss=$(printf '%s\n' "$out" | awk -F',' '/packet loss/{gsub(/[^0-9.]/, "", $3); print $3; exit}')
    [ -n "$rtt" ] || rtt="—"
    [ -n "$loss" ] || loss="100"
    printf '%s|%s\n' "$rtt" "$loss"
}

cmd_band_get() {
    if [ -f "$BAND_FILE" ] && grep -qx '1' "$BAND_FILE" 2>/dev/null; then
        echo "1"
    else
        echo "0"
    fi
}

cmd_band_set() {
    mkdir -p "$CACHE_DIR"
    case "${1:-0}" in
        1|on|true) echo 1 > "$BAND_FILE" ;;
        *) echo 0 > "$BAND_FILE" ;;
    esac
    cmd_band_get
}

cmd="${1:-}"
shift || true

case "$cmd" in
    wifi-list) cmd_wifi_list "${1:-}" ;;
    wifi-connect) cmd_wifi_connect "$@" ;;
    wifi-radio) cmd_wifi_radio "${1:-get}" ;;
    dns-get) cmd_dns_get ;;
    dns-set) cmd_dns_set "$@" ;;
    ping-once) cmd_ping_once ;;
    band-get) cmd_band_get ;;
    band-set) cmd_band_set "${1:-0}" ;;
    *)
        echo "usage: $0 wifi-list|wifi-connect|wifi-radio|dns-get|dns-set|ping-once|band-get|band-set" >&2
        exit 2
        ;;
esac
