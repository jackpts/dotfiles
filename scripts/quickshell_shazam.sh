#!/usr/bin/env bash
set -euo pipefail

# Simple CLI wrapper for QuickShell Shazam module using songrec.
# Captures a short sample from the default PipeWire/PulseAudio source
# into a temporary WAV file and asks songrec to recognize it.
#
# Usage:
#   quickshell_shazam.sh          # prints a one-line summary or an error
#   quickshell_shazam.sh --raw    # prints raw songrec output
#
# NOTE:
#   - Ensure `songrec` is installed and in PATH.
#   - Use pavucontrol (or similar) to route this recording to your
#     monitor device (what-you-hear) if needed.

DURATION="10"          # seconds to record
RATE="44100"           # sample rate
CHANNELS="2"           # stereo
TMP_WAV="/tmp/quickshell_shazam_$$.wav"
RAW_OUTPUT="false"

if [[ "${1-}" == "--raw" ]]; then
  RAW_OUTPUT="true"
fi

cleanup() {
  [[ -f "$TMP_WAV" ]] && rm -f "$TMP_WAV"
}
trap cleanup EXIT

if ! command -v songrec >/dev/null 2>&1; then
  echo "songrec not found in PATH" >&2
  exit 1
fi

# Prefer pw-record (PipeWire). Fallback to parec (PulseAudio).
RECORD_CMD=""
if command -v pw-record >/dev/null 2>&1; then
  # pw-record does not support a --duration flag, so we use timeout to
  # limit the recording length.
  RECORD_CMD=(pw-record --rate "$RATE" --channels "$CHANNELS" "$TMP_WAV")
elif command -v parec >/dev/null 2>&1; then
  # parec will use the default source; you can change it with PULSE_SOURCE
  RECORD_CMD=(parec --file-format=wav "$TMP_WAV")
else
  echo "Neither pw-record nor parec found; cannot capture audio" >&2
  exit 1
fi

# Record a short sample with timeout so the command stops after DURATION seconds.
# We ignore the exit code from timeout/pw-record and validate the file instead.
if command -v timeout >/dev/null 2>&1; then
  set +e
  timeout "$DURATION" "${RECORD_CMD[@]}" >/dev/null 2>&1
  rec_status=$?
  set -e
else
  # Fallback: run in background and sleep, then kill.
  set +e
  "${RECORD_CMD[@]}" >/dev/null 2>&1 &
  rec_pid=$!
  sleep "$DURATION"
  kill "$rec_pid" >/dev/null 2>&1 || true
  wait "$rec_pid" 2>/dev/null
  rec_status=$?
  set -e
fi

# Basic validation: file must exist and be non-empty.
if [[ ! -s "$TMP_WAV" ]]; then
  echo "Failed to record audio sample" >&2
  exit 1
fi

# Recognize the recorded file
if ! OUTPUT=$(songrec audio-file-to-recognized-song "$TMP_WAV" 2>/dev/null); then
  echo "No match or recognition failed" >&2
  exit 1
fi

if [[ "$RAW_OUTPUT" == "true" ]]; then
  echo "$OUTPUT"
  exit 0
fi

# Try to extract a concise summary from songrec output.
# Prefer jq when available (songrec returns JSON), with grep/sed as a fallback.
SUMMARY=""

if command -v jq >/dev/null 2>&1 && printf '%s' "$OUTPUT" | head -n1 | grep -q "^{"; then
  # JSON output: build "artist - title (Album)" when album metadata is available.
  SUMMARY=$(printf '%s\n' "$OUTPUT" | jq -r '
    def fmt($t):
      # Base: "artist - title"
      ($t.subtitle // "") + " - " + ($t.title // "")
      | . as $base
      # Try to find album in sections[0].metadata where title == "Album"
      | ( $t.sections[0].metadata // []
          | map(select(.title == "Album"))
          | .[0].text // ""
        ) as $album
      | if ($album | length) > 0 then
          $base + " [" + $album + "]"
        else
          $base
        end;

    if (has("track") and .track != null) then
      fmt(.track)
    elif (has("matches") and (.matches | length) > 0 and .matches[0].track != null) then
      fmt(.matches[0].track)
    else
      "No match"
    end
  ' 2>/dev/null || echo "")
fi

if [[ -z "$SUMMARY" ]]; then
  # Fallback for non-JSON or if jq failed: look for Title/Artist/Album lines.
  TITLE=$(printf '%s\n' "$OUTPUT" | grep -m1 -i "^Title:" | sed 's/^Title:[[:space:]]*//') || true
  ARTIST=$(printf '%s\n' "$OUTPUT" | grep -m1 -i "^Artist:" | sed 's/^Artist:[[:space:]]*//') || true
  ALBUM=$(printf '%s\n' "$OUTPUT" | grep -m1 -i "^Album:" | sed 's/^Album:[[:space:]]*//') || true

  if [[ -n "${TITLE:-}" || -n "${ARTIST:-}" ]]; then
    if [[ -n "${ARTIST:-}" ]]; then
      SUMMARY+="$ARTIST - "
    fi
    SUMMARY+="${TITLE:-Unknown title}"
    if [[ -n "${ALBUM:-}" ]]; then
      SUMMARY+=" ($ALBUM)"
    fi
  else
    # Last-resort fallback: first non-empty line (may still be ugly).
    SUMMARY=$(printf '%s\n' "$OUTPUT" | sed '/^$/d' | head -n1)
  fi
fi

SUMMARY=${SUMMARY:-"No match"}
printf '%s\n' "$SUMMARY"
