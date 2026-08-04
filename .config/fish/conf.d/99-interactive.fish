# 99-interactive.fish
# UI niceties and interactive-only actions. Runs late.

# Greeting
# set -U fish_greeting
# set -U fish_greeting "Weather update: (curl -s 'wttr.in?format=%C+%t')"
set -U fish_greeting "Welcome, "(whoami)", to Fish Shell on "(uname -n)" running "(uname -o)" "(uname -r)""

# Key bindings
fish_vi_key_bindings

# One-time fastfetch per session (with 1s timeout)
if status is-interactive
    if not set -q __FASTFETCH_STARTED
        set -gx __FASTFETCH_STARTED 1
        if type -q fastfetch
            timeout 1 fastfetch 2>/dev/null
        else if type -q neofetch
            timeout 1 neofetch 2>/dev/null
        end
    end
end

