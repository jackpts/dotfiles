#!/bin/bash

backup() {
    cur_Date=$(date +"%Y-%b-%d-%H_00")
    outputDir="/run/media/jacky/back2up/regular"

    if [ ! -d "$outputDir" ]; then
        echo -e "Directory $outputDir doesn't exist!"
        exit 1
    fi

    clear
    outputFile="$outputDir/backup-$cur_Date.7z"
    echo "Backup started to: $outputFile"
    # gum spin --spinner dot --title "Backup started to: $outputFile" -- sleep 3

    ls -1 ~/.local/share/gnome-shell/extensions/ >$HOME/soft/gnome_ext_list.txt
    pacman -Qqen >$HOME/soft/pkglist_pacman.txt
    pacman -Qqem >$HOME/soft/pkglist_aur.txt
    # snap list >$HOME/soft/pkglist_snap.txt
    flatpak list >$HOME/soft/pkglist_flatpak.txt

    rsync -avh --progress /usr/share/themes/ /run/media/jacky/back2up/once/themes/
    rsync -avh --progress /usr/share/sddm/themes/ /run/media/jacky/back2up/once/sddm_themes/

    backupArr=(
        "$HOME/Nextcloud"
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/systemd/resolved.conf"
        "/etc/systemd/system.conf"
        "/etc/profile"
        "/etc/nsswitch.conf"
        "/etc/fstab"
        "/etc/locale.conf"
        "/etc/vconsole.conf"
        "/etc/systemd/logind.conf"
        "/etc/pacman.conf"
        "/etc/pacman.d/mirrorlist"
        "/etc/sddm.conf"
        # "/boot/refind_linux.conf"
        # "/boot/EFI/refind/refind.conf"
        "$HOME/.config/fish"
        # "$HOME/.local/share/remmina"
        "$HOME/.gnupg"
        "$HOME/.ssh"
        "$HOME/vpn"
        "$HOME/soft/*.txt"
        "$HOME/.git*"
        "$HOME/.config/nvim"
        "$HOME/.vimrc"
        "$HOME/.config/alacritty/*.toml"
        "$HOME/.tmux.conf"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.config/catnap/*.toml"
        "$HOME/.config/mpd/mpd.conf"
        "$HOME/.config/hypr/"
        "$HOME/.config/waybar/"
        "$HOME/.config/rofi/"
        "$HOME/.config/wofi/"
        "$HOME/.config/swaync/"
        "$HOME/.config/wlogout/"
        "$HOME/.config/ghostty/"
        "$HOME/.config/kitty/"
        "$HOME/.config/kdeconnect"
        "$HOME/.ncmpcpp/config"
        "$HOME/scripts/"
        "$HOME/.prettierrc"
        "$HOME/dotfiles"
        "/usr/share/wayland-sessions/hyprland.desktop"
        "/usr/share/rofi/themes/"
        "/usr/share/applications/"
    )

    for b in "${backupArr[@]}"; do
        7z u -bt "$outputFile" -spf2 "$b" -xr!.git >/dev/null
        echo "--> $b"
    done

    fileSize="$(du -sh $outputFile | awk '{print $1}')"
    echo "Backup finished, size is: $fileSize"
    notify-send -u normal -i dialog-information \
        "Hi, $(whoami)!" "Backup is complete.\nFile: $cur_Date [$fileSize]."
}

backup "$@"
