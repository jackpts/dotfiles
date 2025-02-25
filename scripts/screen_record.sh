#!/usr/bin/env bash

subdirRecord="Screenrecorder"
dirRecord=$(xdg-user-dir VIDEOS)/${subdirRecord}
rofiTheme="$HOME/.config/rofi/screenrec.rasi"
temp_file="${dirRecord}/temp_recording.mp4"
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

toggle_recording() {
    if pgrep -x "wf-recorder" >/dev/null; then
        pkill wf-recorder
        notify-send "Recording Stopped"

        if [ -e $temp_file ]; then
            output="${dirRecord}/recording_$(getdate).gif"
            notify-send "Converting Temp Rec file in GIF.."
            temp_output="${output%.*}_temp.gif"
            ffmpeg -i $temp_file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -f gif $temp_output
            notify-send "Optimizing GIF now.."

            # creating colors palette
            ffmpeg -i $temp_file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos,palettegen" -y $temp_palette
            # unique colors calc
            num_colors=$(magick $temp_palette -unique-colors txt:- | wc -l)
            echo "unique colors in palette is: $num_colors"

            if [ "$num_colors" -gt 2 ] && [ "$num_colors" -lt 256 ]; then
                gifsicle -O3 $temp_output -o $output --colors $num_colors
            else
                gifsicle -O3 $temp_output -o $output --colors 256
            fi

            rm $temp_file $temp_output /tmp/palette.png

            if [ -e $output ]; then
                notify-send "Saving GIF finished: $output"
            else
                notify-send "Error saving GIF!"
            fi
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
            geometry=$(slurp)
            width_height=$(echo $geometry | cut -d'+' -f1)
            width=$(echo $width_height | cut -d'x' -f1)
            height=$(echo $width_height | cut -d'x' -f2)

            if [ -e $temp_file ]; then
                rm $temp_file
            fi

            wf-recorder --pixel-format yuv420p -f $temp_file -g $geometry &
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
