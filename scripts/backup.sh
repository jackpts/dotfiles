#!/bin/bash

backup() {
    cur_Date=$(date +"%y-%b-%d-%h_00")
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
    rsync -avh --progress /usr/share/plymouth/themes/ /run/media/jacky/back2up/once/plymouth_themes/

    backupArr=(
        "$HOME/Nextcloud"
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/systemd/resolved.conf"
        "/etc/systemd/system.conf"
        "/etc/systemd/logind.conf" # KillUserProcesses=yes
        "/etc/profile"
        "/etc/nsswitch.conf"
        "/etc/fstab"
        "/etc/locale.conf"
        "/etc/vconsole.conf"
        "/etc/pacman.conf"
        "/etc/pacman.d/mirrorlist"
        "/etc/sddm.conf"
        "/etc/plymouth/plymouthd.conf"
        "/etc/mkinitcpio.conf"
        "/etc/default/grub"
        # "/boot/refind_linux.conf"
        # "/boot/EFI/refind/refind.conf"
        "$HOME/.config/fish"
        # "$HOME/.local/share/remmina"
        "$HOME/.gnupg"
        "$HOME/.password-store/"
        "$HOME/.ssh"
        "$HOME/vpn"
        "$HOME/soft/*.txt"
        "$HOME/.git*"
        "$HOME/.config/kdeconnect"
        "$HOME/dotfiles"
        "/usr/share/wayland-sessions/hyprland.desktop"
        "/usr/share/rofi/themes/"
        "/usr/share/applications/"
        "$HOME/.config/gtk-3.0/settings.ini"
        "$HOME/.config/gtk-4.0/settings.ini"
    )

    for b in "${backupArr[@]}"; do
        # 7z u -bt -t7z -m0=lzma -mx=9 "$outputFile" -spf2 -p"$(pass backup)" "$b" -xr!.git -xr!node_modules >/dev/null
        7z u -bt -t7z -m0=lzma -mx=9 "$outputFile" -spf2 -p1 "$b" -xr!.git -xr!node_modules >/dev/null
        echo "--> $b"
    done

    fileSize="$(du -sh $outputFile | awk '{print $1}')"
    echo "Backup finished, size is: $fileSize"
    notify-send -u normal -i dialog-information \
        "Hi, $(whoami)!" "Backup is complete.\nFile: $cur_Date [$fileSize]."
}

backup "$@"
