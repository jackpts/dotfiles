#!/bin/bash

# Distribution check
if [[ ! -f /etc/arch-release ]]; then
    echo -e "\e[31mError: This script works only on Arch Linux\e[0m"
    exit 1
fi

# Configuration
LOGO_PATH=~/dotfiles/.config/fastfetch/she-logo.jpg
SCALE=0.3
TERM_WIDTH=$(tput cols)
IMAGE_WIDTH=$((TERM_WIDTH * 30 / 100))

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m'

# Generate system info
generate_text() {
    # System information gathering
    read -r OS_NAME OS_VERSION < <(grep -E '^NAME=|^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    KERNEL=$(uname -r)
    HOST=$(hostnamectl --static)
    CPU=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
    CORES=$(nproc)
    MEMORY=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    RESOLUTION=$(xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}' || echo "Undefined (Xorg not running)")
    SHELL=$(basename "$SHELL")
    PACKAGES=$(pacman -Qq | wc -l)
    DE=$(echo "$XDG_CURRENT_DESKTOP" | tr -d ' ')
    WM=$(wmctrl -m 2>/dev/null | grep 'Name:' | awk '{print $2}' || echo "Undefined")
    GTK_THEME=$(grep 'gtk-theme-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null | cut -d= -f2 || echo "Default")
    ICON_THEME=$(grep 'gtk-icon-theme-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null | cut -d= -f2 || echo "Default")
    TERMINAL=$(ps -o comm= -p $(ps -o ppid= -p $$))
    DISPLAY_MANAGER=$(systemctl status display-manager 2>/dev/null |
        grep -Po 'loaded \K\S+' |
        xargs basename 2>/dev/null |
        cut -d. -f1 || echo "Undefined")
    INIT_SYSTEM=$(ps -p 1 -o comm=)
    PUBLIC_IP=$(curl -s http://ident.me  2>/dev/null || echo "Failed to retrieve")
    UPTIME=$(uptime -p | sed 's/up //')

    # OS age calculation
    if birth_install=$(stat -c %W / 2>/dev/null); then
        if [ "$birth_install" -ne 0 ]; then
            current=$(date +%s)
            days=$(((current - birth_install) / 86400))
            OS_AGE="${days} days"
        else
            OS_AGE="Unknown (installation time not detected)"
        fi
    else
        OS_AGE="Error: Filesystem doesn't support creation time"
    fi

    # Format output
    echo -e "${GREEN}OS:${NC} $OS_NAME $OS_VERSION"
    echo -e "${GREEN}Kernel:${NC} $KERNEL"
    echo -e "${GREEN}Host:${NC} $HOST"
    echo -e "${GREEN}CPU:${NC} $CPU ($CORES cores)"
    echo -e "${GREEN}Memory:${NC} $MEMORY"
    echo -e "${GREEN}Resolution:${NC} $RESOLUTION"
    echo -e "${GREEN}Shell:${NC} $SHELL"
    echo -e "${GREEN}Packages:${NC} $PACKAGES (official)"
    echo -e "${GREEN}DE/WM:${NC} $DE / $WM"
    echo -e "${GREEN}GTK Theme:${NC} $GTK_THEME"
    echo -e "${GREEN}Icons:${NC} $ICON_THEME"
    echo -e "${GREEN}Terminal:${NC} $TERMINAL"
}

# Generate image with chafa
generate_image() {
    chafa --scale="$SCALE" \
        --symbols solid+all \
        --colors 256 \
        --fill=block \
        --align left \
        "$LOGO_PATH"
}

# Main execution
image_output=$(generate_image)
text_output=$(generate_text | sed 's/\x1b\[[0-9;]*m//g')

# Save outputs to temporary files
image_file=$(mktemp)
text_file=$(mktemp)
echo "$image_output" > "$image_file"
echo "$text_output" > "$text_file"

# Combine outputs side by side using paste
combined_output=$(mktemp)
paste -d ' ' "$image_file" "$text_file" > "$combined_output"

# Display the combined output
cat "$combined_output"

# Clean up temporary files
rm "$image_file" "$text_file" "$combined_output"
