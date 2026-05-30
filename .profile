# Source sway/wlroots env vars for display manager sessions.
# SDDM's wayland-session script sources ~/.profile before the compositor.
env_file="${XDG_CONFIG_HOME:-$HOME/.config}/sway/env"
if [ -r "$env_file" ]; then
    set -a
    . "$env_file"
    set +a
fi
