#!/usr/bin/env bash

subdirRecord="Screenrecorder"
dirRecord=$(xdg-user-dir VIDEOS)/${subdirRecord}
rofiTheme="$HOME/.config/rofi/screenrec.rasi"
temp_file="temp_recording.mp4"
temp_palette="/tmp/palette.png"

mkdir -p "${dirRecord}"

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    pactl list sources | grep 'Name' | grep -v 'monitor' | cut -d ' ' -f2
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

covert_mp4_to_gif() {
    notify-send "Converting Temp Rec file in GIF.." &&
        ffmpeg -i $1 -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -f gif $2
}

optimize_gif() {
    notify-send "Optimizing GIF now.." &&
        ffmpeg -i $1 -vf "fps=10,scale=iw/2:ih/2:flags=lanczos,palettegen" -y $temp_palette &&
        num_colors=$(magick $temp_palette -unique-colors txt:- | wc -l) &&
        notify-send "Unique colors in palette is: $num_colors" && check_gif_colors $num_colors
}

check_gif_colors() {
    if [ "$1" -gt 2 ] && [ "$1" -lt 256 ]; then
        gifsicle -O3 $temp_output -o $output --colors $1
    else
        gifsicle -O3 $temp_output -o $output --colors 256
    fi
}

toggle_recording() {
    if pgrep -x "wf-recorder" >/dev/null; then
        pkill wf-recorder
        notify-send "Recording Stopped"
        sleep 1
        cd ${dirRecord} || exit 1

        if [ -e $temp_file ]; then
            output="recording_$(getdate).gif"
            temp_output="${output%.*}_temp.gif"
            covert_mp4_to_gif $temp_file $temp_output && optimize_gif $temp_file &&
                notify-send "Saving GIF finished: $output" && rm $temp_file $temp_output $temp_palette &
        fi
    else
        chosen=$(
            rofi -dmenu -p "Select Recording Option" -theme ${rofiTheme} <<EOF
Record fullscreen
Record fullscreen with sound
Record selected area
Record selected area with sound
Record selected area in GIF
EOF
        )

        cd ${dirRecord} || exit 1

        case ${chosen} in
        "Record fullscreen")
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t &
            notify-send "Recording [fullscreen] started"
            disown
            ;;
        "Record fullscreen with sound")
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --audio="$(getaudiooutput)" &
            notify-send "Recording [fullscreen with sound] started"
            disown
            ;;
        "Record selected area")
            wf-recorder --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --geometry "$(slurp)" &
            notify-send "Recording [selected area] started"
            disown
            ;;
        "Record selected area with sound")
            wf-recorder --pixel-format yuv420p -f "./recording_$(getdate).mp4" -t --geometry "$(slurp)" --audio="$(getaudiooutput)" &
            notify-send "Recording [selected area with sound] started"
            disown
            ;;
        "Record selected area in GIF")
            if [ -e $temp_file ]; then
                rm $temp_file
            fi

            wf-recorder --pixel-format yuv420p -f $temp_file -t --geometry "$(slurp)" &
            notify-send "Recording [selected area in GIF] started"
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
