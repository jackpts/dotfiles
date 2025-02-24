#!/usr/bin/env bash

subdirRecord="Screenrecorder"
dirRecord=$(xdg-user-dir VIDEOS)/${subdirRecord}
rofiTheme="$HOME/.config/rofi/screenrec.rasi"

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    pactl list sources | grep 'Name' | grep -v 'monitor' | cut -d ' ' -f2
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

toggle_recording() {
    if pgrep -x "wf-recorder" >/dev/null; then
        pkill wf-recorder
        notify-send "Recording Stopped"
    else
        chosen=$(
Record with sound
Record fullscreen with sound
            rofi -dmenu -p "Select Recording Option" -theme ${rofiTheme} <<EOF
Record fullscreen
Record selected area
EOF
        )

        cd ${dirRecord} || exit 1

        case ${chosen} in
        "Record with sound")
            wf-recorder --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --geometry "$(slurp)" --audio="$(getaudiooutput)" &
            notify-send "Recording Started"
            disown
            ;;
        "Record fullscreen with sound")
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --audio="$(getaudiooutput)" &
            notify-send "Recording Started"
            disown
            ;;
        "Record fullscreen")
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t &
            notify-send "Recording Started"
            disown
            ;;
        "Record selected area")
            wf-recorder --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --geometry "$(slurp)" &
            notify-send "Recording Started"
            disown
            ;;
        esac
    fi
}

get_recording_state() {
    if pgrep -x "wf-recorder" >/dev/null; then
        echo '{"text": "", "tooltip": "Recording: ON", "class": "on"}'
    else
        echo '{"text": "", "tooltip": "Recording: OFF", "class": "off"}'
    fi
}

case "$1" in
--toggle)
    toggle_recording
    ;;
*)
    get_recording_state
    ;;
esac
