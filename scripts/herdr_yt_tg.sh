#!/usr/bin/env bash
# mod+t helper: prepare the herdr workspace, then start ghostty.
#
# ghostty autostarts herdr itself (ghostty config `command = …/herdr`), which
# mirrors kitty's `shell /usr/bin/tmux`. This script only prepares the tabs:
#
#   yt-tg     - runs yt-tg-chat-bot, but only when no instance is running
#   dotfiles  - shell parked in ~/dotfiles, ready for daily changes
#
# Existing tabs are reused by position (1st/2nd tab of the first workspace) and
# renamed once; afterwards the labels are the lookup key.

set -uo pipefail

HERDR_BIN="${HERDR_BIN:-$HOME/.local/bin/herdr}"
REPO="$HOME/github/yt-tg-chat-bot"
DOTFILES="$HOME/dotfiles"
BOT_TAB_LABEL="yt-tg"
DOT_TAB_LABEL="dotfiles"
BOT_CMD="cd $REPO && RUST_LOG=info cargo run --bin yt-tg-chat-bot"
SHELL_NAMES=" fish bash zsh sh dash "

log() { printf 'herdr_yt_tg: %s\n' "$*" >&2; }

# Drop herdr pane markers so a manual run from inside a pane still opens a
# top-level client instead of tripping the "nested herdr" guard.
launch_ghostty() {
    exec env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
        -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH ghostty
}

# herdr CLI without stderr noise; callers check for empty output.
h() { "$HERDR_BIN" "$@" 2>/dev/null; }

# Start the headless server when nothing answers on the socket yet.
ensure_server() {
    h tab list >/dev/null && return 0
    log "herdr server not running, starting it"
    setsid "$HERDR_BIN" server >/dev/null 2>&1 &
    local _
    for _ in $(seq 1 100); do
        h tab list >/dev/null && return 0
        sleep 0.1
    done
    return 1
}

# First workspace (lowest number), created when the session is empty.
ensure_workspace() {
    local ws
    ws=$(h workspace list | jq -r '.result.workspaces | sort_by(.number) | .[0].workspace_id // empty')
    if [ -z "$ws" ]; then
        ws=$(h workspace create --cwd "$REPO" --label "$BOT_TAB_LABEL" \
            | jq -r '.result.workspace.workspace_id // empty')
    fi
    printf '%s' "$ws"
}

tab_by_label() {
    h tab list | jq -r --arg l "$1" \
        '[.result.tabs[] | select(.label == $l)][0].tab_id // empty'
}

# Nth tab of a workspace, ordered like the sidebar (public tab numbers).
nth_tab() {
    h tab list | jq -r --arg ws "$1" --argjson n "$2" \
        '[.result.tabs[] | select(.workspace_id == $ws)] | sort_by(.number) | .[$n - 1].tab_id // empty'
}

pane_of_tab() {
    h pane list | jq -r --arg t "$1" \
        '[.result.panes[] | select(.tab_id == $t)][0].pane_id // empty'
}

pane_cwd() {
    h pane get "$1" | jq -r '.result.pane.cwd // empty'
}

# True when the shell itself owns the pane, so typing a command is safe.
pane_foreground() {
    h pane process-info --pane "$1" \
        | jq -r '[.result.process_info.foreground_processes[]?.name] | join(" ")'
}

shell_only() {
    local name
    for name in $1; do
        case "$SHELL_NAMES" in
            *" $name "*) ;;
            *) return 1 ;;
        esac
    done
    return 0
}

# Wait until the pane's shell (and nothing else) owns the foreground, e.g. while
# restored panes spawn fish and render their greeting. `tries` is in 100ms steps;
# a still-busy pane makes this give up instead of typing into a running program.
wait_for_shell() {
    local pane="$1" tries="${2:-30}" procs _
    for _ in $(seq 1 "$tries"); do
        procs=$(pane_foreground "$pane")
        [ -n "$procs" ] && shell_only "$procs" && return 0
        sleep 0.1
    done
    return 1
}

# Retry pane lookup: restored panes can appear a moment after the server starts.
wait_for_pane() {
    local tab="$1" pane _
    for _ in $(seq 1 50); do
        pane=$(pane_of_tab "$tab")
        if [ -n "$pane" ]; then
            printf '%s' "$pane"
            return 0
        fi
        sleep 0.1
    done
    return 1
}

bot_running() {
    # Matches the bot binary and its `cargo run --bin ...` parent, but not an
    # editor or helper that merely has the repo path in its command line.
    pgrep -f 'yt-tg-chat-bot($|[[:space:]])' >/dev/null 2>&1
}

# Reuse the tab at <index> when it already sits in <expected_cwd>, otherwise
# create a labelled tab. Prints the tab id.
ensure_tab() {
    local label="$1" index="$2" expected_cwd="$3" tab pane out
    tab=$(tab_by_label "$label")
    if [ -n "$tab" ]; then
        printf '%s' "$tab"
        return 0
    fi

    tab=$(nth_tab "$WS" "$index")
    if [ -n "$tab" ]; then
        pane=$(pane_of_tab "$tab")
        if [ -n "$pane" ] && [ "$(pane_cwd "$pane")" = "$expected_cwd" ]; then
            log "renaming tab $tab to $label"
            h tab rename "$tab" "$label" >/dev/null
            printf '%s' "$tab"
            return 0
        fi
    fi

    log "creating tab $label"
    out=$(h tab create --workspace "$WS" --cwd "$expected_cwd" --label "$label")
    printf '%s' "$(jq -r '.result.tab.tab_id // empty' <<<"$out")"
}

if ! ensure_server; then
    log "cannot reach herdr, opening ghostty only"
    launch_ghostty
fi

WS=$(ensure_workspace)
if [ -z "$WS" ]; then
    log "no herdr workspace available, opening ghostty only"
    launch_ghostty
fi

BOT_TAB=$(ensure_tab "$BOT_TAB_LABEL" 1 "$REPO")
DOT_TAB=$(ensure_tab "$DOT_TAB_LABEL" 2 "$DOTFILES")

# Bot: skip when an instance already runs anywhere (including the kitty/tmux
# fallback), so two pollers never share the same bot.db.
if [ -n "$BOT_TAB" ] && ! bot_running; then
    BOT_PANE=$(wait_for_pane "$BOT_TAB")
    if [ -n "$BOT_PANE" ] && wait_for_shell "$BOT_PANE" 50; then
        log "starting yt-tg-chat-bot in $BOT_PANE"
        h pane run "$BOT_PANE" "$BOT_CMD" >/dev/null
    else
        log "yt-tg pane is busy, not starting the bot"
    fi
fi

# dotfiles: park the shell in ~/dotfiles, nothing else.
if [ -n "$DOT_TAB" ]; then
    DOT_PANE=$(wait_for_pane "$DOT_TAB")
    if [ -n "$DOT_PANE" ] && wait_for_shell "$DOT_PANE" 10; then
        case "$(pane_cwd "$DOT_PANE")" in
            "$DOTFILES" | "$DOTFILES"/*) ;;
            *)
                log "switching $DOT_PANE to $DOTFILES"
                h pane run "$DOT_PANE" "cd $DOTFILES" >/dev/null
                ;;
        esac
    fi
fi

# Land on the bot tab; ghostty autostarts herdr and attaches to this state.
h workspace focus "$WS" >/dev/null
[ -n "$BOT_TAB" ] && h tab focus "$BOT_TAB" >/dev/null

launch_ghostty
