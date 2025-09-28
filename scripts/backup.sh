#!/bin/bash

backup() {
    cur_Date=$(date +"%d_%b-%H_%M")
    outputDir="/run/media/jacky/back2up/regular"

    if [ ! -d "$outputDir" ]; then
        echo -e "Directory $outputDir doesn't exist!"
        exit 1
    fi

    clear
    outputFile="$outputDir/backup-$cur_Date.7z"
    echo "Backup started to: $outputFile"
    # gum spin --spinner dot --title "Backup started to: $outputFile" -- sleep 3

    if [ ! -d "$HOME/soft/" ]; then
        mkdir -p "$HOME/soft/"
    fi

    ls -1 ~/.local/share/gnome-shell/extensions/ >$HOME/soft/gnome_ext_list.txt
    pacman -Qqen >$HOME/soft/pkglist_pacman.txt
    pacman -Qqem >$HOME/soft/pkglist_aur.txt
    # snap list >$HOME/soft/pkglist_snap.txt
    flatpak list >$HOME/soft/pkglist_flatpak.txt
    # dconf dump /org/gnome/shell/extensions/ > $HOME/soft/ext-dump.txt
    
    dconf dump /org/nemo/ > $HOME/dotfiles/nemo-dconf-settings
    # To restore: dconf load /org/nemo/ < ~/dotfiles/nemo-dconf-settings

    rsync -avh --progress /usr/share/themes/ /run/media/jacky/back2up/once/themes/
    rsync -avh --progress /usr/share/sddm/themes/ /run/media/jacky/back2up/once/sddm_themes/
    rsync -avh --progress /usr/share/plymouth/themes/ /run/media/jacky/back2up/once/plymouth_themes/

    SFSfile=$(find $HOME/Documents/ -type f -name "sfs*.json" -printf "%T+ %f\n" | sort -r | head -n 1 | awk '{print $2}')

    # MySQL DB backup
    echo "Backin up MySQL base..."
    mysql_date=$(date +"%Y-%m-%d")
    mysql_file="mysql_dump_$mysql_date.sql"
    mariadb-dump --all-databases --host=127.0.0.1 --port=33066 > "$HOME/soft/$mysql_file"

    backupArr=(
        # "$HOME/Nextcloud"
        "$HOME/obsidian/"
        "/etc/bluetooth/main.conf"
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
        "/etc/pam.d/sddm*"
        "/etc/plymouth/plymouthd.conf"
        "/etc/mkinitcpio.conf"
        "/etc/default/grub"
        "/etc/security/faillock.conf"
        "/etc/wireguard/wginno.conf"
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
        "$HOME/.gnupg/"
        "$HOME/dotfiles"
        "/usr/share/wayland-sessions/hyprland.desktop"
        "/usr/share/rofi/themes/"
        "/usr/share/applications/"
        "$HOME/.config/gtk-3.0/"    # Nemo Bookmarks here
        "$HOME/.config/gtk-4.0/"
        "$HOME/Documents/$SFSfile"
        "$HOME/Documents/browser/"
        "$HOME/.my.cnf" # `chmod 600 ~/.my.cnf`
        "$HOME/soft/$mysql_file"
    )

    for b in "${backupArr[@]}"; do
        # 7z a -bt -t7z -m0=lzma -mx=9 "$outputFile" -spf2 -p"$(pass backup)" "$b" -xr!.git -xr!node_modules >/dev/null
        7z a -bt -t7z -m0=lzma -mx=9 "$outputFile" -spf2 -p1 "$b" -xr!.git -xr!.venv -xr!node_modules -xr!themes >/dev/null
        echo "--> $b"
    done


    rm "$HOME/soft/$mysql_file"

    fileSize="$(du -sh $outputFile | awk '{print $1}')"
    echo "Backup finished, size is: $fileSize"
    notify-send -u normal -i dialog-information \
        "Hi, $(whoami)!" "Backup is complete.\nFile: $cur_Date [$fileSize]."
}

backup "$@"
