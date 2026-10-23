# 99-interactive.fish
# UI niceties and interactive-only actions. Runs late.

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

