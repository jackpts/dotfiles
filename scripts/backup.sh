#!/bin/bash

backup() {
    cur_Date=$(date +"%d%b-%H")
    outputDir="/run/media/jacky/back2up/regular"

    if [ ! -d "$outputDir" ]; then
        echo -e "Directory $outputDir doesn't exist!"
        exit 1
    fi

    ls -1 ~/.local/share/gnome-shell/extensions/ >$HOME/soft/gnome_ext_list.txt
    pacman -Qqen >$HOME/soft/pkglist_pacman.txt
    pacman -Qqem >$HOME/soft/pkglist_aur.txt

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
        "/boot/refind_linux.conf"
        "/boot/EFI/refind/refind.conf"
        "$HOME/.config/fish"
        "$HOME/.local/share/remmina"
        "$HOME/Documents/pgp"
        "$HOME/.gnupg"
        "$HOME/.ssh"
        "$HOME/vpn"
        "$HOME/soft/gnome_ext_list.txt"
        "$HOME/soft/pkglist_pacman.txt"
        "$HOME/soft/pkglist_aur.txt"
        "$HOME/.git*"
        "$HOME/.config/nvim"
        "$HOME/.vimrc"
        "$HOME/.vim_runtime/vimrcs"
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
        "$HOME/.config/ghostty/"
        "$HOME/.config/kitty/"
        "$HOME/.ncmpcpp/config"
        "$HOME/scripts/"
        "$HOME/.prettierrc"
        "/usr/share/wayland-sessions/hyprland.desktop"
        "/usr/share/rofi/themes/"
        "/usr/share/applications/"
    )

    for b in "${backupArr[@]}"; do
        7z u -bt "$outputDir/all-$cur_Date.7z" -spf2 "$b"
    done
}

backup "$@"
backup "$@" && sleep 1 && notify-send 'Backup complete'
