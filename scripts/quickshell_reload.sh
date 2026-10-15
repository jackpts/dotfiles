#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/dotfiles/.config/quickshell/jackbar"
lock_file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-jackbar.reload.lock"
# How long to wait for another reload to finish instead of failing.
# This makes console `q_reload` always work: concurrent calls queue up.
lock_timeout=15
# How long to wait for the old instance to exit after kill.
kill_timeout=4
poll_interval=0.1

qs_running() {
    quickshell list -p "$cfg" 2>/dev/null | grep -q '^Instance '
}

# Best-effort kill BEFORE taking the lock.
# Heals the stale lock held by daemons started by the old script version
# (it leaked fd 9 into `quickshell -d`, so the daemon held the flock forever).
# Killing here releases that stale lock so the flock below can succeed.
quickshell kill -p "$cfg" 2>/dev/null || true

exec 9>"$lock_file"
if ! flock -w "$lock_timeout" 9; then
    echo "quickshell reload: timed out ($lock_timeout s) waiting for lock $lock_file" >&2
    echo "hint: lsof -t '$lock_file' shows the holder; kill it once to heal a stale lock" >&2
    exit 1
fi

# Kill under lock (covers races: instance started between pre-lock kill and lock).
quickshell kill -p "$cfg" 2>/dev/null || true

# Wait for exit, re-issuing kill ~1x/sec in case something respawns it.
# Old script: 50 x (kill + 0.2s) = up to 10s + extra sleep 1. New: ~4s total.
steps=$(awk -v t="$kill_timeout" -v i="$poll_interval" 'BEGIN{printf "%d", (t/i)+0.5}')
for ((i = 1; i <= steps; i++)); do
    qs_running || break
    if (( i % 10 == 0 )); then quickshell kill -p "$cfg" 2>/dev/null || true; fi
    sleep "$poll_interval"
done

if qs_running; then
    # Last resort: SIGKILL by PID from JSON list, then short grace period.
    pids=$(quickshell list -p "$cfg" -j 2>/dev/null | grep -o '"pid":[0-9]*' | grep -o '[0-9]*' || true)
    if [ -n "${pids:-}" ]; then
        # shellcheck disable=SC2086
        kill -9 $pids 2>/dev/null || true
        for _ in $(seq 1 10); do
            qs_running || break
            sleep 0.1
        done
    fi
fi

if qs_running; then
    echo "failed to stop existing quickshell instance" >&2
    exit 1
fi

# Release the lock BEFORE starting the daemon. The old script did
# `exec quickshell -d ...` while holding fd 9, leaking the flock into the
# daemon so every later reload failed with "already in progress".
flock -u 9
exec 9>&-

exec quickshell -d -n -p "$cfg" "$@"
