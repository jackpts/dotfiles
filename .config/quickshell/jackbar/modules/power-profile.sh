#!/usr/bin/env bash
# power-profile.sh — get/set platform power profiles for jackbar BatteryGauge
#
# Usage:
#   power-profile.sh get          →  current|id1,id2,...
#   power-profile.sh set <id>     →  sets profile (power-saver|balanced|performance)
#
# Prefers power-profiles-daemon (powerprofilesctl) when available, otherwise
# ACPI /sys/firmware/acpi/platform_profile. Sysfs writes need root; we try
# an unprivileged write first, then pkexec.

ACPI="/sys/firmware/acpi/platform_profile"
ACPI_CHOICES="/sys/firmware/acpi/platform_profile_choices"

to_canonical() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-')" in
        power-saver|low-power|power) echo "power-saver" ;;
        balanced|balance-performance|balance-power|default) echo "balanced" ;;
        performance) echo "performance" ;;
        custom) echo "custom" ;;
        *) printf '%s' "$1" ;;
    esac
}

to_acpi() {
    case "$1" in
        power-saver) echo "low-power" ;;
        balanced) echo "balanced" ;;
        performance) echo "performance" ;;
        *) printf '%s' "$1" ;;
    esac
}

has_ppd() {
    command -v powerprofilesctl >/dev/null 2>&1
}

unique_csv() {
    local seen="" out="" id
    for id in "$@"; do
        [ -n "$id" ] || continue
        case ",$seen," in
            *",$id,"*) continue ;;
        esac
        seen="${seen:+$seen,}$id"
        out="${out:+$out,}$id"
    done
    printf '%s' "$out"
}

list_ppd() {
    local ids="" line key
    while IFS= read -r line; do
        case "$line" in
            "  "[a-z]*:|*[a-z]*:)
                key=$(printf '%s' "$line" | sed -n 's/^[* ]*\([^:]*\):.*/\1/p' | tr -d ' ')
                key=$(to_canonical "$key")
                case "$key" in
                    power-saver|balanced|performance) ids="$ids $key" ;;
                esac
                ;;
        esac
    done < <(powerprofilesctl list 2>/dev/null)
    # shellcheck disable=SC2086
    unique_csv $ids
}

list_acpi() {
    local ids="" tok canon
    [ -r "$ACPI_CHOICES" ] || return 0
    for tok in $(tr -d '\n' < "$ACPI_CHOICES"); do
        canon=$(to_canonical "$tok")
        case "$canon" in
            power-saver|balanced|performance) ids="$ids $canon" ;;
        esac
    done
    # shellcheck disable=SC2086
    unique_csv $ids
}

get_current() {
    if has_ppd; then
        to_canonical "$(powerprofilesctl get 2>/dev/null)"
        return
    fi
    if [ -r "$ACPI" ]; then
        to_canonical "$(tr -d '\n' < "$ACPI")"
        return
    fi
    echo "unknown"
}

get_available() {
    local avail=""
    if has_ppd; then
        avail=$(list_ppd)
    fi
    if [ -z "$avail" ]; then
        avail=$(list_acpi)
    fi
    if [ -z "$avail" ]; then
        avail="power-saver,balanced,performance"
    fi
    printf '%s' "$avail"
}

set_ppd() {
    powerprofilesctl set "$1"
}

set_acpi() {
    local val="$1"
    if [ -w "$ACPI" ]; then
        printf '%s\n' "$val" > "$ACPI"
        return
    fi
    printf '%s\n' "$val" | pkexec tee "$ACPI" >/dev/null
}

cmd="${1:-get}"

case "$cmd" in
    get)
        printf '%s|%s\n' "$(get_current)" "$(get_available)"
        ;;
    set)
        want="${2:-}"
        case "$want" in
            power-saver|balanced|performance) ;;
            *) echo "invalid profile: ${want}" >&2; exit 2 ;;
        esac
        if has_ppd; then
            set_ppd "$want"
        elif [ -e "$ACPI" ]; then
            set_acpi "$(to_acpi "$want")"
        else
            echo "no power profile backend" >&2
            exit 1
        fi
        printf '%s|%s\n' "$(get_current)" "$(get_available)"
        ;;
    *)
        echo "usage: $0 get | set <power-saver|balanced|performance>" >&2
        exit 2
        ;;
esac
