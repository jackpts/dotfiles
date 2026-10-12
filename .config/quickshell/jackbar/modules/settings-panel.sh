#!/usr/bin/env bash
# settings-panel.sh — system settings helpers for jackbar SettingsPanel
#
# Usage:
#   settings-panel.sh brightness get          → current|max
#   settings-panel.sh brightness set <pct>    → sets brightnessctl percent
#   settings-panel.sh font get                → 12
#   settings-panel.sh font set <px>           → gsettings + swaymsg font
#   settings-panel.sh scale get               → 1.25
#   settings-panel.sh scale set <factor>       → swaymsg output * scale
#   settings-panel.sh theme colors            → ["#rrggbb",...]
#   settings-panel.sh theme apply             → wal from current wallpaper
#   settings-panel.sh wallpaper name          → basename
#   settings-panel.sh colorpicker             → launches wl-color-picker (detached)
#   settings-panel.sh wallpaper open          → kitty wallpaper picker
#   settings-panel.sh reminder set <mins> <text...>
#       → confirmation toast now + delayed toast after <mins>

set -euo pipefail

HOME_DIR="${HOME:-}"
WALLPAPER_LAST="$HOME_DIR/.config/sway/wallpaper_last"
WALLPAPER_CONF="$HOME_DIR/.config/sway/wallpaper.conf"
WAL_COLORS_JSON="$HOME_DIR/.cache/wal/colors.json"
WAL_COLORS_SH="$HOME_DIR/.cache/wal/colors.sh"
UPDATE_THEME="$HOME_DIR/dotfiles/scripts/update_term_theme.sh"
WALLPAPER_SCRIPT="$HOME_DIR/dotfiles/scripts/wallpaper.sh"
DEFAULT_FONT_FAMILY="Cantarell"
DEFAULT_FONT_SIZE=12

die() {
    echo "$*" >&2
    exit 1
}

usage() {
    cat >&2 <<'EOF'
usage: settings-panel.sh <command> ...
  brightness get|set <pct>
  font get|set <px>
  scale get|set <factor>
  theme colors|apply
  wallpaper name|open
  colorpicker
  reminder set <minutes> <text...>
EOF
    exit 2
}

current_wallpaper() {
    if [ -r "$WALLPAPER_LAST" ]; then
        local p
        p=$(tr -d '\n' < "$WALLPAPER_LAST")
        if [ -n "$p" ] && [ -f "$p" ]; then
            printf '%s' "$p"
            return 0
        fi
    fi
    if [ -r "$WALLPAPER_CONF" ]; then
        local p
        p=$(sed -n 's/^wallpaper="\(.*\)"/\1/p' "$WALLPAPER_CONF" | head -1)
        if [ -n "$p" ] && [ -f "$p" ]; then
            printf '%s' "$p"
            return 0
        fi
    fi
    if [ -r "$HOME_DIR/.config/waypaper/config.ini" ]; then
        local p
        p=$(grep '^wallpaper =' "$HOME_DIR/.config/waypaper/config.ini" | cut -d'=' -f2- | tr -d ' "')
        p=$(eval echo "$p")
        if [ -n "$p" ] && [ -f "$p" ]; then
            printf '%s' "$p"
            return 0
        fi
    fi
    return 1
}

cmd_brightness_get() {
    local cur max
    cur=$(brightnessctl get 2>/dev/null || echo 0)
    max=$(brightnessctl max 2>/dev/null || echo 100)
    printf '%s|%s\n' "$cur" "$max"
}

cmd_brightness_set() {
    local pct="${1:-}"
    [[ "$pct" =~ ^[0-9]+$ ]] || die "invalid brightness percent: $pct"
    if [ "$pct" -lt 1 ]; then pct=1; fi
    if [ "$pct" -gt 100 ]; then pct=100; fi
    brightnessctl set "${pct}%" >/dev/null
    cmd_brightness_get
}

font_family_from_gsettings() {
    local raw family
    raw=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || true)
    # raw looks like: 'Cantarell 11'
    raw=${raw#\'}
    raw=${raw%\'}
    if [ -z "$raw" ]; then
        printf '%s' "$DEFAULT_FONT_FAMILY"
        return
    fi
    family=$(printf '%s' "$raw" | sed -E 's/[[:space:]]+[0-9]+(\.[0-9]+)?$//')
    if [ -z "$family" ]; then
        family="$DEFAULT_FONT_FAMILY"
    fi
    printf '%s' "$family"
}

cmd_font_get() {
    local raw size
    raw=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || true)
    raw=${raw#\'}
    raw=${raw%\'}
    size=$(printf '%s' "$raw" | sed -nE 's/.*[[:space:]]+([0-9]+)(\.[0-9]+)?$/\1/p')
    if [[ ! "$size" =~ ^[0-9]+$ ]]; then
        size="$DEFAULT_FONT_SIZE"
    fi
    printf '%s\n' "$size"
}

cmd_font_set() {
    local px="${1:-}"
    local family
    [[ "$px" =~ ^[0-9]+$ ]] || die "invalid font size: $px"
    if [ "$px" -lt 10 ]; then px=10; fi
    if [ "$px" -gt 20 ]; then px=20; fi
    family=$(font_family_from_gsettings)
    gsettings set org.gnome.desktop.interface font-name "${family} ${px}" 2>/dev/null || true
    if command -v swaymsg >/dev/null 2>&1; then
        swaymsg "font pango:${family} ${px}" >/dev/null 2>&1 || true
    fi
    printf '%s\n' "$px"
}

cmd_scale_get() {
    local scale
    if ! command -v swaymsg >/dev/null 2>&1; then
        echo "1"
        return
    fi
    scale=$(swaymsg -t get_outputs -r 2>/dev/null | python3 -c '
import json, sys
try:
    outs = json.load(sys.stdin)
except Exception:
    print("1")
    raise SystemExit
focused = None
active = None
for o in outs:
    if o.get("focused"):
        focused = o
    if o.get("active") and active is None:
        active = o
src = focused or active or (outs[0] if outs else None)
if not src:
    print("1")
else:
    s = src.get("scale", 1)
    print(s if s else 1)
' 2>/dev/null || echo 1)
    printf '%s\n' "$scale"
}

cmd_scale_set() {
    local factor="${1:-}"
    [[ "$factor" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid scale: $factor"
    if command -v swaymsg >/dev/null 2>&1; then
        swaymsg "output * scale ${factor}" >/dev/null
    fi
    printf '%s\n' "$factor"
}

cmd_theme_colors() {
    if [ -r "$WAL_COLORS_JSON" ]; then
        python3 -c '
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
colors = data.get("colors") or {}
order = [f"color{i}" for i in range(16)]
out = []
for k in order:
    v = colors.get(k)
    if v:
        out.append(v if v.startswith("#") else f"#{v}")
if not out:
    special = data.get("special") or {}
    for k in ("background", "foreground", "cursor"):
        v = special.get(k)
        if v:
            out.append(v if v.startswith("#") else f"#{v}")
print(json.dumps(out))
' "$WAL_COLORS_JSON"
        return
    fi
    if [ -r "$WAL_COLORS_SH" ]; then
        # shellcheck disable=SC1090
        python3 -c '
import re, json, sys
text = open(sys.argv[1]).read()
found = re.findall(r"color([0-9]+)=[\"'\'']?(#[0-9A-Fa-f]{6})", text)
found.sort(key=lambda t: int(t[0]))
print(json.dumps([c for _, c in found]))
' "$WAL_COLORS_SH"
        return
    fi
    echo "[]"
}

cmd_theme_apply() {
    local wall
    if wall=$(current_wallpaper); then
        if command -v wal >/dev/null 2>&1; then
            wal -i "$wall" -q || wal -i "$wall"
            cmd_theme_colors
            return 0
        fi
    fi
    if [ -x "$UPDATE_THEME" ] || [ -f "$UPDATE_THEME" ]; then
        sh "$UPDATE_THEME" || true
        cmd_theme_colors
        return 0
    fi
    die "no wallpaper or pywal available"
}

cmd_wallpaper_name() {
    local wall
    if wall=$(current_wallpaper); then
        basename "$wall"
    else
        echo ""
    fi
}

cmd_wallpaper_open() {
    if ! command -v kitty >/dev/null 2>&1; then
        die "kitty not found"
    fi
    kitty --title wallpaper "$WALLPAPER_SCRIPT" &
    disown || true
}

cmd_colorpicker() {
    # Must run detached: jackbar Settings PopupWindow holds pointer/keyboard grab,
    # and Quickshell Process would block/kill an interactive Wayland picker.
    local out="${XDG_RUNTIME_DIR:-/tmp}/jackbar-colorpick.txt"
    : >"$out" 2>/dev/null || true

    save_clip_hex() {
        local clip
        clip=$(wl-paste -n 2>/dev/null || true)
        case "$clip" in
            \#*[0-9A-Fa-f]*|[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]*)
                printf '%s\n' "$clip" >"$out"
                ;;
        esac
    }

    # Prefer wl-color-picker on Sway (hyprpicker often fails with invalid stride)
    if command -v wl-color-picker >/dev/null 2>&1; then
        (
            # `clipboard` = pick pixel via slurp/grim and copy hex (no zenity dialog)
            wl-color-picker clipboard >/dev/null 2>&1 || true
            save_clip_hex
        ) >/dev/null 2>&1 &
        disown || true
        printf 'started|wl-color-picker\n'
        return 0
    fi

    if command -v hyprpicker >/dev/null 2>&1; then
        (
            hex=$(hyprpicker -a -n -f hex -q 2>/dev/null | tail -n1 | tr -d '\r')
            if [ -n "$hex" ]; then
                printf '%s\n' "$hex" >"$out"
            else
                save_clip_hex
            fi
        ) >/dev/null 2>&1 &
        disown || true
        printf 'started|hyprpicker\n'
        return 0
    fi

    die "no color picker found (install wl-color-picker)"
}

# reminder set <minutes> <text...>
# Prints: ok|<HH:MM>|<minutes>|<unit_label>
# Schedules a background notify-send so it survives panel close / qs reload.
cmd_reminder_set() {
    local mins="${1:-}"
    shift || true
    local text="$*"
    text=$(printf '%s' "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    [[ "$mins" =~ ^[0-9]+$ ]] || die "invalid minutes: $mins"
    if [ "$mins" -lt 1 ]; then
        die "minutes must be >= 1"
    fi
    if [ "$mins" -gt 10080 ]; then
        die "minutes too large (max 7 days)"
    fi
    if [ -z "$text" ]; then
        die "reminder text required"
    fi
    if ! command -v notify-send >/dev/null 2>&1; then
        die "notify-send not found"
    fi

    local unit_label at_time secs title body
    if [ "$mins" -eq 1 ]; then
        unit_label="1 minute"
    else
        unit_label="${mins} minutes"
    fi
    at_time=$(date -d "+${mins} minutes" +%H:%M 2>/dev/null || date -v+"${mins}M" +%H:%M 2>/dev/null)
    if [ -z "${at_time:-}" ]; then
        at_time=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now()+timedelta(minutes=int('${mins}'))).strftime('%H:%M'))")
    fi
    secs=$((mins * 60))
    title="${text} in ${unit_label}"
    body="You'll be reminded at ${at_time}"

    # Immediate confirmation toast (matches reference: title + "You'll be reminded at HH:MM")
    notify-send -u low -a "Reminders" -i appointment-new --hint=string:x-canonical-private-synchronous:jackbar-reminder-set \
        "$title" "$body" || notify-send -u low -a "Reminders" "$title" "$body"

    # Delayed reminder — detached so it outlives this process / quickshell reload
    (
        sleep "$secs"
        notify-send -u critical -a "Reminders" -i appointment-soon \
            "Reminder" "$text" || notify-send -u critical -a "Reminders" "Reminder" "$text"
    ) >/dev/null 2>&1 &
    disown || true

    printf 'ok|%s|%s|%s\n' "$at_time" "$mins" "$unit_label"
}

main() {
    local group="${1:-}" action="${2:-}"
    case "$group" in
        brightness)
            case "$action" in
                get) cmd_brightness_get ;;
                set) cmd_brightness_set "${3:-}" ;;
                *) usage ;;
            esac
            ;;
        font)
            case "$action" in
                get) cmd_font_get ;;
                set) cmd_font_set "${3:-}" ;;
                *) usage ;;
            esac
            ;;
        scale)
            case "$action" in
                get) cmd_scale_get ;;
                set) cmd_scale_set "${3:-}" ;;
                *) usage ;;
            esac
            ;;
        theme)
            case "$action" in
                colors) cmd_theme_colors ;;
                apply) cmd_theme_apply ;;
                *) usage ;;
            esac
            ;;
        wallpaper)
            case "$action" in
                name) cmd_wallpaper_name ;;
                open) cmd_wallpaper_open ;;
                *) usage ;;
            esac
            ;;
        colorpicker)
            cmd_colorpicker
            ;;
        reminder)
            case "$action" in
                set)
                    shift 2 || true
                    # remaining: <mins> <text...>
                    cmd_reminder_set "$@"
                    ;;
                *) usage ;;
            esac
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
