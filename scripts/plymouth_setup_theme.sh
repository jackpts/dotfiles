#!/bin/bash

# Directory containing Plymouth themes
THEMES_DIR="/usr/share/plymouth/themes"
CONFIG_FILE="/etc/plymouth/plymouthd.conf"

# Check if Plymouth is installed
if ! command -v plymouth &>/dev/null; then
    echo "Plymouth is not installed. Please install it first."
    exit 1
fi

# Get a list of installed themes
THEMES=($(ls -1 "$THEMES_DIR"))

# Check if any themes are installed
if [ ${#THEMES[@]} -eq 0 ]; then
    echo "No Plymouth themes found in $THEMES_DIR."
    exit 1
fi

# Display available themes
echo "Available Plymouth themes:"
for i in "${!THEMES[@]}"; do
    echo "$((i + 1)). ${THEMES[$i]}"
done

# Prompt user to select a theme
read -p "Enter the number of the theme you want to use: " THEME_NUM

# Validate user input
if [[ ! "$THEME_NUM" =~ ^[0-9]+$ ]] || [ "$THEME_NUM" -lt 1 ] || [ "$THEME_NUM" -gt ${#THEMES[@]} ]; then
    echo "Invalid selection. Please try again."
    exit 1
fi

# Get the selected theme name
SELECTED_THEME="${THEMES[$((THEME_NUM - 1))]}"

# Update the Plymouth configuration file
if grep -q "^Theme=" "$CONFIG_FILE"; then
    # Replace the existing theme
    sudo sed -i "s/^Theme=.*/Theme=$SELECTED_THEME/" "$CONFIG_FILE"
else
    # Add the theme line if it doesn't exist
    echo "Theme=$SELECTED_THEME" | sudo tee -a "$CONFIG_FILE" >/dev/null
fi

# Regenerate initramfs
echo "Updating initramfs with the new theme..."
sudo mkinitcpio -P

echo "Plymouth theme has been set to '$SELECTED_THEME' and initramfs has been updated."
