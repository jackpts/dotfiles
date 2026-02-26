#!/usr/bin/env bash

subdirRecord="Screenrecorder"
dirRecord=$(xdg-user-dir VIDEOS)/${subdirRecord}
rofiTheme="$HOME/.config/rofi/screenrec.rasi"
temp_file="temp_recording.mp4"
temp_palette="/tmp/palette.png"
RECORD_MODE_FILE="/tmp/screenrec_mode"

# Temporary mixing sink and state
AUDIO_NULL_SINK_NAME="screenrec_mix"
AUDIO_STATE_FILE="/tmp/screenrec_audio_modules"

mkdir -p "${dirRecord}"

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

# Returns the monitor source of the current default sink (i.e., system/desktop audio)
get_default_sink_monitor() {
    # Prefer newer pactl command if available
    if command -v pactl >/dev/null 2>&1; then
        local sink
        sink=$(pactl get-default-sink 2>/dev/null)
        if [ -n "$sink" ]; then
            echo "${sink}.monitor"
            return
        fi
        # Fallback for older pactl
        sink=$(pactl info | awk -F': ' '/Default Sink:/ {print $2}')
        if [ -n "$sink" ]; then
            echo "${sink}.monitor"
            return
        fi
        # Last resort: first available monitor source
        pactl list sources short | awk '{print $2}' | grep '\.monitor$' | head -n1
    fi
}

# Returns the current default microphone source (if needed for future use)
get_default_source() {
    if command -v pactl >/dev/null 2>&1; then
        local src
        src=$(pactl get-default-source 2>/dev/null)
        if [ -n "$src" ]; then
            echo "$src"
            return
        fi
        pactl info | awk -F': ' '/Default Source:/ {print $2}'
    fi
}

# Unload any temporary mix modules created for recording
cleanup_audio_mix() {
    if [ -f "$AUDIO_STATE_FILE" ]; then
        read -r null_id loop_sys loop_mic < "$AUDIO_STATE_FILE"
        # Unload loopbacks first, then the null sink
        [ -n "$loop_sys" ] && pactl unload-module "$loop_sys" >/dev/null 2>&1
        [ -n "$loop_mic" ] && pactl unload-module "$loop_mic" >/dev/null 2>&1
        [ -n "$null_id" ] && pactl unload-module "$null_id" >/dev/null 2>&1
        rm -f "$AUDIO_STATE_FILE"
    fi
}

# Create a temporary null sink and loop back both system audio and microphone into it.
# Returns the monitor source of that sink for wf-recorder.
setup_audio_mix() {
    # Clean any previous session leftovers
    cleanup_audio_mix >/dev/null 2>&1

    local monitor mic null_id loop_sys loop_mic default_sink default_rate
    monitor="$(get_default_sink_monitor)"
    mic="$(get_default_source)"

    # Cache current default sink so creating the null sink doesn't steal default
    default_sink=$(pactl get-default-sink 2>/dev/null || pactl info | awk -F': ' '/Default Sink:/ {print $2}')

    # Derive system default sample rate for compatibility
    default_rate=$(pactl info | awk -F': ' '/Default Sample Rate:/ {print $2}')
    if [ -z "$default_rate" ]; then
        # Parse from Default Sample Specification if needed (e.g., s16le 2ch 48000Hz)
        default_rate=$(pactl info | awk -F': ' '/Default Sample Specification:/ {print $2}' | grep -oE '[0-9]+')
    fi
    default_rate=${default_rate:-48000}

    # Create null sink to mix into (match system rate, stereo)
    null_id=$(pactl load-module module-null-sink \
        sink_name="$AUDIO_NULL_SINK_NAME" \
        sink_properties="device.description=Screenrec Mix" \
        channels=2 rate="$default_rate" 2>/dev/null)

    # If creating null sink failed, fall back to system audio only
    if [ -z "$null_id" ]; then
        echo "$monitor"
        return
    fi

    # Ensure default sink remains what it was (avoid module-switch-on-connect effects)
    if [ -n "$default_sink" ]; then
        pactl set-default-sink "$default_sink" >/dev/null 2>&1
    fi

    # Loop system audio (default sink monitor) into the null sink (use safer latency)
    if [ -n "$monitor" ]; then
        loop_sys=$(pactl load-module module-loopback source="$monitor" sink="$AUDIO_NULL_SINK_NAME" latency_msec=50 sink_dont_move=1 source_dont_move=1 adjust_time=0 2>/dev/null)
    fi

    # Loop microphone into the null sink (use same latency)
    if [ -n "$mic" ]; then
        loop_mic=$(pactl load-module module-loopback source="$mic" sink="$AUDIO_NULL_SINK_NAME" latency_msec=50 sink_dont_move=1 source_dont_move=1 adjust_time=0 2>/dev/null)
    fi

    printf "%s %s %s\n" "$null_id" "${loop_sys:-}" "${loop_mic:-}" > "$AUDIO_STATE_FILE"

    echo "${AUDIO_NULL_SINK_NAME}.monitor"
}

getactivemonitor() {
    swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
}

# Get active window geometry string for wf-recorder ("x,y WxH")
getactivewindow() {
    swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"'
}

# Get active window region string for gpu-screen-recorder ("WxH+X+Y")
get_window_region() {
    swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | "\(.rect.width)x\(.rect.height)+\(.rect.x)+\(.rect.y)"'
}

# Detect if gpu-screen-recorder is available
has_gsr() {
    command -v gpu-screen-recorder >/dev/null 2>&1
}

set_record_mode() {
    printf '%s\n' "$1" > "$RECORD_MODE_FILE"
}

is_gif_mode() {
    [ -f "$RECORD_MODE_FILE" ] && [ "$(cat "$RECORD_MODE_FILE" 2>/dev/null)" = "gif" ]
}

clear_record_mode() {
    rm -f "$RECORD_MODE_FILE"
}

# Wrapper function to start wf-recorder with error handling
start_wf_recorder() {
    local cmd="$1"
    # Start recording in background and capture any immediate errors
    $cmd 2>/dev/null &
    local pid=$!
    sleep 0.5
    # Check if process is still running (indicates success)
    if kill -0 $pid 2>/dev/null; then
        return 0
    else
        notify-send "Recording Error" "wf-recorder failed to start. Check logs."
        return 1
    fi
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
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        # Stop whichever recorder is running
        if pgrep -x "wf-recorder" >/dev/null; then
            pkill wf-recorder
        fi
        if pgrep -f "gpu-screen-recorder" >/dev/null; then
            pkill -SIGINT -f gpu-screen-recorder
        fi
        notify-send "Recording Stopped"
        sleep 1
        cd ${dirRecord} || exit 1

        if is_gif_mode && [ -e "$temp_file" ]; then
            output="recording_$(getdate).gif"
            temp_output="${output%.*}_temp.gif"
            covert_mp4_to_gif "$temp_file" "$temp_output" && optimize_gif "$temp_file" &&
                notify-send "Saving GIF finished: $output" && rm -f "$temp_file" "$temp_output" "$temp_palette" &
        fi
        # Tear down any temporary audio mixing modules
        cleanup_audio_mix
        clear_record_mode
    else
        chosen=$(
            rofi -dmenu -p "Select Recording Option" -theme ${rofiTheme} <<EOF
Record fullscreen
Record fullscreen with sound
Record selected area
Record selected area with sound
Record selected area in GIF
Record window
Record window with sound
EOF
        )

        cd ${dirRecord} || exit 1

        case ${chosen} in
        "Record fullscreen")
            set_record_mode "video"
            if has_gsr; then
                gpu-screen-recorder -w "$(getactivemonitor)" -f 60 -q high -o "./recording_$(getdate).mp4" &
            else
                wf-recorder -o "$(getactivemonitor)" -f "./recording_$(getdate).mp4" &
            fi
            notify-send "Recording [fullscreen] started"
            disown
            ;;
        "Record fullscreen with sound")
            set_record_mode "video"
            if has_gsr; then
                gpu-screen-recorder -w "$(getactivemonitor)" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
            else
                wf-recorder -o "$(getactivemonitor)" -f "./recording_$(getdate).mp4" --audio="$(setup_audio_mix)" &
            fi
            notify-send "Recording [fullscreen with system+mic audio] started"
            disown
            ;;
        "Record selected area")
            set_record_mode "video"
            if has_gsr; then
                gpu-screen-recorder -w region -region "$(slurp -f "%wx%h+%x+%y")" -f 60 -q high -o "./recording_$(getdate).mp4" &
            else
                wf-recorder -f "./recording_$(getdate).mp4" --geometry "$(slurp)" &
            fi
            notify-send "Recording [selected area] started"
            disown
            ;;
        "Record selected area with sound")
            set_record_mode "video"
            if has_gsr; then
                gpu-screen-recorder -w region -region "$(slurp -f "%wx%h+%x+%y")" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
            else
                wf-recorder -f "./recording_$(getdate).mp4" --geometry "$(slurp)" --audio="$(setup_audio_mix)" &
            fi
            notify-send "Recording [selected area with system+mic audio] started"
            disown
            ;;
        "Record selected area in GIF")
            set_record_mode "gif"
            rm -f "$temp_file"
            if has_gsr; then
                gpu-screen-recorder -w region -region "$(slurp -f "%wx%h+%x+%y")" -f 30 -q medium -o "$temp_file" &
            else
                wf-recorder -f "$temp_file" --geometry "$(slurp)" &
            fi
            notify-send "Recording [selected area in GIF] started"
            disown
            ;;
        "Record window")
            set_record_mode "video"
            if has_gsr; then
                region="$(get_window_region)"
                if [ -n "$region" ]; then
                    gpu-screen-recorder -w region -region "$region" -f 60 -q high -o "./recording_$(getdate).mp4" &
                    notify-send "Recording [active window] started" "Region: $region"
                    disown
                else
                    notify-send "Error" "Could not get active window geometry"
                fi
            else
                window_geom=$(getactivewindow)
                if [ -n "$window_geom" ]; then
                    wf-recorder -f "./recording_$(getdate).mp4" --geometry "$window_geom" &
                    notify-send "Recording [active window] started" "Geometry: $window_geom"
                    disown
                else
                    notify-send "Error" "Could not get active window geometry"
                fi
            fi
            ;;
        "Record window with sound")
            set_record_mode "video"
            if has_gsr; then
                region="$(get_window_region)"
                if [ -n "$region" ]; then
                    gpu-screen-recorder -w region -region "$region" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
                    notify-send "Recording [active window with system+mic audio] started" "Region: $region"
                    disown
                else
                    notify-send "Error" "Could not get active window geometry"
                fi
            else
                window_geom=$(getactivewindow)
                if [ -n "$window_geom" ]; then
                    wf-recorder -f "./recording_$(getdate).mp4" --geometry "$window_geom" --audio="$(setup_audio_mix)" &
                    notify-send "Recording [active window with system+mic audio] started" "Geometry: $window_geom"
                    disown
                else
                    notify-send "Error" "Could not get active window geometry"
                fi
            fi
            ;;
        esac
    fi
}

get_recording_state() {
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        echo '{"text": "", "tooltip": "Recording: ON", "class": "on"}'
    else
        echo '{"text": "", "tooltip": "Recording: OFF", "class": "off"}'
    fi
}

# Direct recording functions for parameter support
start_fullscreen_recording() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        gpu-screen-recorder -w "$(getactivemonitor)" -f 60 -q high -o "./recording_$(getdate).mp4" &
    else
        wf-recorder -o "$(getactivemonitor)" -f "./recording_$(getdate).mp4" &
    fi
    notify-send "Recording [fullscreen] started"
    disown
}

start_fullscreen_recording_with_sound() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        gpu-screen-recorder -w "$(getactivemonitor)" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
    else
        wf-recorder -o "$(getactivemonitor)" -f "./recording_$(getdate).mp4" --audio="$(setup_audio_mix)" &
    fi
    notify-send "Recording [fullscreen with system+mic audio] started"
    disown
}

start_area_recording() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        gpu-screen-recorder -w region -region "$(slurp -f "%wx%h+%x+%y")" -f 60 -q high -o "./recording_$(getdate).mp4" &
    else
        wf-recorder -f "./recording_$(getdate).mp4" --geometry "$(slurp)" &
    fi
    notify-send "Recording [selected area] started"
    disown
}

start_area_recording_with_sound() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        gpu-screen-recorder -w region -region "$(slurp -f "%wx%h+%x+%y")" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
    else
        wf-recorder -f "./recording_$(getdate).mp4" --geometry "$(slurp)" --audio="$(setup_audio_mix)" &
    fi
    notify-send "Recording [selected area with system+mic audio] started"
    disown
}

start_window_recording() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        region="$(get_window_region)"
        if [ -n "$region" ]; then
            gpu-screen-recorder -w region -region "$region" -f 60 -q high -o "./recording_$(getdate).mp4" &
            notify-send "Recording [active window] started"
            disown
        else
            notify-send "Error" "Could not get active window geometry"
        fi
    else
        window_geom=$(getactivewindow)
        if [ -n "$window_geom" ]; then
            wf-recorder -f "./recording_$(getdate).mp4" --geometry "$window_geom" &
            notify-send "Recording [active window] started"
            disown
        else
            notify-send "Error" "Could not get active window geometry"
        fi
    fi
}

start_window_recording_with_sound() {
    cd ${dirRecord} || exit 1
    set_record_mode "video"
    if has_gsr; then
        region="$(get_window_region)"
        if [ -n "$region" ]; then
            gpu-screen-recorder -w region -region "$region" -f 60 -q high -a "default_output|default_input" -o "./recording_$(getdate).mp4" &
            notify-send "Recording [active window with system+mic audio] started"
            disown
        else
            notify-send "Error" "Could not get active window geometry"
        fi
    else
        window_geom=$(getactivewindow)
        if [ -n "$window_geom" ]; then
            wf-recorder -f "./recording_$(getdate).mp4" --geometry "$window_geom" --audio="$(setup_audio_mix)" &
            notify-send "Recording [active window with system+mic audio] started"
            disown
        else
            notify-send "Error" "Could not get active window geometry"
        fi
    fi
}

start_gif_recording() {
    cd ${dirRecord} || exit 1
    set_record_mode "gif"
    rm -f "$temp_file"
    wf-recorder -f "$temp_file" --geometry "$(slurp)" &
    notify-send "Recording [selected area in GIF] started"
    disown
}

stop_recording() {
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        if pgrep -x "wf-recorder" >/dev/null; then
            pkill wf-recorder
        fi
        if pgrep -f "gpu-screen-recorder" >/dev/null; then
            pkill -SIGINT -f gpu-screen-recorder
        fi
        notify-send "Recording Stopped"
        sleep 1
        cd ${dirRecord} || exit 1

        if is_gif_mode && [ -e "$temp_file" ]; then
            output="recording_$(getdate).gif"
            temp_output="${output%.*}_temp.gif"
            covert_mp4_to_gif "$temp_file" "$temp_output" && optimize_gif "$temp_file" &&
                notify-send "Saving GIF finished: $output" && rm -f "$temp_file" "$temp_output" "$temp_palette" &
        fi
        # Tear down any temporary audio mixing modules
        cleanup_audio_mix
        clear_record_mode
    fi
}

case "$1" in
--toggle)
    toggle_recording
    ;;
--stop)
    stop_recording
    ;;
--fullscreen)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_fullscreen_recording
    fi
    ;;
--fullscreen-sound)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_fullscreen_recording_with_sound
    fi
    ;;
--area)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_area_recording
    fi
    ;;
--area-sound)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_area_recording_with_sound
    fi
    ;;
--window)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_window_recording
    fi
    ;;
--window-sound)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_window_recording_with_sound
    fi
    ;;
--gif)
    if pgrep -x "wf-recorder" >/dev/null || pgrep -f "gpu-screen-recorder" >/dev/null; then
        stop_recording
    else
        start_gif_recording
    fi
    ;;
*)
    get_recording_state
    ;;
esac
