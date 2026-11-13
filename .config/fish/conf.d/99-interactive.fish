# 99-interactive.fish
# UI niceties and interactive-only actions. Runs late.

# Tide draws the prompt asynchronously: a background fish renders it into the
# universal var `_tide_prompt_$fish_pid`, and this shell only learns about it
# through fish's universal-variable notifier, which watches the *config
# directory* for writes. When `fish_variables` is a symlink (e.g. created by
# `stow .`), the writes happen in the symlink target's directory instead, the
# notifier never fires, and the prompt keeps showing the previous git
# branch/status until a keypress forces a repaint.
if status is-interactive; and test -L $__fish_config_dir/fish_variables
    set_color yellow
    echo "fish: $__fish_config_dir/fish_variables is a symlink; tide's async prompt" \
        "updates will lag until the next keypress - keep it a regular file." >&2
    set_color normal
end

# Greeting
# set -U fish_greeting
# set -U fish_greeting "Weather update: (curl -s 'wttr.in?format=%C+%t')"
set -U fish_greeting "Welcome, "(whoami)", to Fish Shell on "(uname -n)" running "(uname -o)" "(uname -r)""

# Key bindings
fish_vi_key_bindings

# One-time fetch per session
# neofetch everywhere (including herdr panes). Herdr has kitty graphics disabled,
# so the image backend falls back to ASCII art there instead of the custom image.
if status is-interactive
    if not set -q __NEOFETCH_STARTED
        set -gx __NEOFETCH_STARTED 1
        if type -q neofetch
            neofetch
        end
    end
end

