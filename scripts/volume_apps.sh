#!/usr/bin/env bash
# List per-app playback (sink-input) volumes for the quickshell volume tooltip.
# Output: single line of HTML rows like
#   "Zen: 129% <font color="#ffcc00">██████████</font><br/>ViberPC: 30% (muted) <font color="#90b1b1">███░░░░░░░</font>",
# sorted by volume desc, no trailing <br/>. Empty output when no sink-inputs.
# Bar style mirrors the Disk Usage module (10 cells, █ filled / ░ empty).
set -euo pipefail

command -v pactl >/dev/null 2>&1 || exit 0

# Pipe-separated list (case-insensitive) of streams to hide from the tooltip.
# Extend as needed, e.g. DENY="speech-dispatcher-dummy|libcanberra".
DENY="speech-dispatcher-dummy|speech-dispatcher"

pactl list sink-inputs 2>/dev/null | awk -v denylist="$DENY" '
    BEGIN {
        nd = split(tolower(denylist), parts, "\\|")
        for (k = 1; k <= nd; k++) deny[parts[k]] = 1
    }
    function esc(s) {
        gsub(/&/, "\\&amp;", s)
        gsub(/</, "\\&lt;", s)
        gsub(/>/, "\\&gt;", s)
        return s
    }
    function flush() {
        if (!have) return
        if (app == "" && fallback != "") app = fallback
        if (app == "") app = "Unknown"
        if (tolower(app) in deny) return
        if (!(app in seen)) {
            seen[app] = 1
            order[++n] = app
            maxvol[app] = 0
            total[app] = 0
            mutedcount[app] = 0
        }
        if (vol + 0 > maxvol[app] + 0) maxvol[app] = vol + 0
        total[app]++
        if (muted == "yes") mutedcount[app]++
    }
    /^Sink Input #/ {
        flush()
        have = 1
        app = ""; fallback = ""; vol = 0; muted = "no"
        next
    }
    /^[[:space:]]*Mute:/ {
        muted = ($2 == "yes") ? "yes" : "no"
        next
    }
    /^[[:space:]]*Volume:/ {
        line = $0
        while (match(line, /[0-9]+%/)) {
            v = substr(line, RSTART, RLENGTH - 1) + 0
            if (v > vol) vol = v
            line = substr(line, RSTART + RLENGTH)
        }
        next
    }
    /^[[:space:]]*application\.name = / {
        app = $0
        sub(/^[^"]*"/, "", app)
        sub(/".*$/, "", app)
        next
    }
    /^[[:space:]]*media\.name = / {
        fallback = $0
        sub(/^[^"]*"/, "", fallback)
        sub(/".*$/, "", fallback)
        next
    }
    END {
        flush()
        for (i = 1; i <= n; i++) {
            a = order[i]
            m = (total[a] > 0 && mutedcount[a] >= total[a]) ? 1 : 0
            printf "%d|%d|%s\n", maxvol[a] + 0, m, esc(a)
        }
    }
' | sort -t'|' -k1,1nr | awk -F'|' '
    # Bar colors mirror the Disk Usage module semantics:
    # muted -> volumeMuted gray, over-amplified (>100%) -> critical red,
    # otherwise the volume gauge yellow.
    function bar(v,   f, s, i) {
        f = int(10 * (v > 100 ? 100 : v) / 100)
        s = ""
        for (i = 0; i < f; i++) s = s "█"
        for (i = f; i < 10; i++) s = s "░"
        return s
    }
    {
        v = $1 + 0; muted = ($2 == 1); a = $3
        c = muted ? "#90b1b1" : (v > 100 ? "#ff6b6b" : "#ffcc00")
        lbl = a ": " v "%" (muted ? " (muted)" : "")
        rows[++n] = lbl " <font color=\"" c "\">" bar(v) "</font>"
    }
    END { for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? "<br/>" : ""), rows[i] }
'
