#!/usr/bin/env bash
# vpn-detect.sh — robust VPN detection for jackbar NetworkIndicator
# Output formats:
#   active|<iface>|<conn_name>|<rx_bytes>|<tx_bytes>
#   down
#
# Detection order (first hit wins):
#   1. NetworkManager: device with TYPE vpn/wireguard in connected state
#   2. NetworkManager: active connection with TYPE vpn/wireguard
#   3. Default-route device looks like a VPN interface (policy-routing setups
#      like Surfshark put `ip route get 1.1.1.1` via surfshark_wg in table 300000)
#   4. Interface-name heuristics over /sys/class/net (tun/tap/wg/tailscale/...)
#
# A candidate is only accepted if the interface exists in /sys/class/net and
# is usable (operstate up/unknown/dormant, or has an IP address). This avoids
# false positives from stale NM profiles or down tunnels.

is_usable_iface() {
    local iface="$1"
    [ -n "$iface" ] || return 1
    [ -d "/sys/class/net/$iface" ] || return 1
    # Ignore loopback / docker / virtual bridges explicitly
    case "$iface" in
        lo|docker*|br-*|veth*|virbr*|lxcbr*) return 1 ;;
    esac
    local oper
    oper=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
    case "$oper" in
        up|unknown|dormant) return 0 ;;
    esac
    # Fallback: interface with an assigned IP is usable even if operstate says down
    if ip -o addr show dev "$iface" 2>/dev/null | grep -q 'inet '; then
        return 0
    fi
    return 1
}

# Matches common VPN interface names. Keep in a function so both
# method 3 and 4 share the pattern list.
is_vpn_name() {
    local name="$1"
    case "$name" in
        tun*|tap*|ppp*|\
        wg*|*_wg|*-wg|wireguard*|wg-*|\
        tailscale*|tailscale0|\
        zt*|zt-*|\
        proton*|mullvad*|nordlynx|ivpn*|pia*|express*|\
        surfshark*|*_vpn|*-vpn|vpn*|\
        utun*|ipsec*|strongswan*|openvpn*|zerotier*)
            return 0 ;;
        *) return 1 ;;
    esac
}

iface=""
conn=""

# --- Method 1: NM device with vpn/wireguard type, connected ---
if command -v nmcli >/dev/null 2>&1; then
    while IFS=: read -r dev typ state; do
        case "$typ" in
            vpn|wireguard)
                case "$state" in
                    connected*)
                        if is_usable_iface "$dev"; then
                            iface="$dev"
                            break
                        fi
                        ;;
                esac
                ;;
        esac
    done < <(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null)

    # --- Method 2: NM active connection with vpn/wireguard type ---
    if [ -z "$iface" ]; then
        while IFS=: read -r name typ dev; do
            case "$typ" in
                vpn|wireguard)
                    if [ -n "$dev" ] && [ "$dev" != "--" ] && is_usable_iface "$dev"; then
                        iface="$dev"
                        conn="$name"
                        break
                    fi
                    ;;
            esac
        done < <(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null)
    fi

    # Remember connection name for the method-1 iface as well
    if [ -n "$iface" ] && [ -z "$conn" ]; then
        conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null \
            | awk -F: -v d="$iface" '$3==d {print $1; exit}')
    fi
fi

# --- Method 3: default-route device is a VPN interface ---
# Handles policy-routing VPNs (Surfshark WireGuard uses table 300000).
if [ -z "$iface" ]; then
    route_dev=$(ip route get 1.1.1.1 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
    if [ -n "$route_dev" ] && is_vpn_name "$route_dev" && is_usable_iface "$route_dev"; then
        iface="$route_dev"
    fi
fi

# --- Method 4: interface-name heuristics over /sys/class/net ---
# Multiple VPN-ish interfaces may exist (e.g. Surfshark creates both
# surfshark_wg and surfshark_ipv6) — pick the one with the most traffic,
# which is the real tunnel carrying data.
if [ -z "$iface" ]; then
    best_traffic=-1
    for path in /sys/class/net/*; do
        cand=${path##*/}
        if is_vpn_name "$cand" && is_usable_iface "$cand"; then
            rx_c=$(cat "/sys/class/net/$cand/statistics/rx_bytes" 2>/dev/null || echo 0)
            tx_c=$(cat "/sys/class/net/$cand/statistics/tx_bytes" 2>/dev/null || echo 0)
            total=$((rx_c + tx_c))
            if [ "$total" -gt "$best_traffic" ]; then
                best_traffic=$total
                iface="$cand"
            fi
        fi
    done
fi

if [ -n "$iface" ]; then
    rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    # conn may legitimately be empty (e.g. tailscale/wg-quick without NM) — keep field anyway
    printf 'active|%s|%s|%s|%s\n' "$iface" "$conn" "$rx" "$tx"
else
    echo "down"
fi
