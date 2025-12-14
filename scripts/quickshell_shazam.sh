#!/usr/bin/env bash
# Helper script for Shazam.qml module in quickshell
# Records a short audio sample and uses songrec to identify the song

set -euo pipefail

# Duration to record (in seconds)
DURATION=12

# Temporary file for recording
TEMP_FILE="/tmp/quickshell_shazam_$(date +%s).wav"

# Cleanup on exit
trap 'rm -f "$TEMP_FILE"' EXIT

# Record audio from default source
# Use parec (PulseAudio) or pw-record (PipeWire) depending on what's available
if command -v pw-record &> /dev/null; then
    # PipeWire
    timeout "$DURATION" pw-record --format=s16 --rate=44100 --channels=2 "$TEMP_FILE" 2>/dev/null || true
elif command -v parec &> /dev/null; then
    # PulseAudio
    timeout "$DURATION" parec --format=s16le --rate=44100 --channels=2 "$TEMP_FILE" 2>/dev/null || true
else
    echo "Error: Neither pw-record nor parec found"
    exit 1
fi

# Check if recording was created
if [[ ! -s "$TEMP_FILE" ]]; then
    echo "No match"
    exit 0
fi

# Use songrec to recognize the song
if OUTPUT=$(songrec audio-file-to-recognized-song "$TEMP_FILE" 2>/dev/null); then
    # Parse the output - songrec outputs JSON
    # Extract artist and track name
    TRACK=$(echo "$OUTPUT" | jq -r '.track.title // empty' 2>/dev/null)
    ARTIST=$(echo "$OUTPUT" | jq -r '.track.subtitle // empty' 2>/dev/null)
    
    if [[ -n "$TRACK" && -n "$ARTIST" ]]; then
        echo "$ARTIST - $TRACK"
    elif [[ -n "$TRACK" ]]; then
        echo "$TRACK"
    else
        echo "No match"
    fi
else
    echo "No match"
fi
