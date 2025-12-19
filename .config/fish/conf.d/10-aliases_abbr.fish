# 10-aliases_abbr.fish
# All aliases and abbreviations. Keep commands only; no functions here.

# Base
alias cp "cp -i"
alias df 'df -h'
alias free 'free -m'
alias cls 'clear'
alias la 'ls -A'
alias l 'ls -alF'
alias ls "eza --color=always --long --git --icons=always"
alias cdi 'zi'
alias cd.. 'cd ..'
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .... 'cd ../../..'
abbr cd 'z'
abbr mkdir 'mkdir -p'
alias z.. 'z ..'
alias logmeout "sudo pkill -u $USER"
alias pacman_clean "pacman -Rsn (pacman -Qdtq)"
alias pacman_clear_cache 'sudo paccache -r'
alias gnome_startup 'gnome-session-properties'
alias rel_info 'cat /etc/*rel*'
abbr duf 'duf --hide loops,special --sort filesystem'
abbr themes 'ls /usr/share/themes'

# Errors
abbr logs 'journalctl -xe'
abbr log_errors 'journalctl -p err -b'
abbr syslog 'sudo dmesg --level=emerg,alert,crit'
abbr sys_acpi 'sudo dmesg | grep ACPI'

# Gnome shell
abbr gnome_errors 'journalctl /usr/bin/gnome-shell -f -o cat'
abbr gnome_ver 'gnome-shell --version'
# abbr ext_create 'gnome-extensions create --interactive'
# abbr ext_list 'gnome-extensions list | grep jack'
# abbr ext_edit 'nvim ~/github/gnome.ext.song.title/extension.js'
# abbr ext_install 'gnome-extensions install ./gnome.ext.song.title.zip --force'
# abbr ext_remove 'gnome-extensions uninstall gnome.ext.song.title@jackpts.github.com'
# abbr ext_pack 'z ~/github; and rm gnome.ext.song.title.zip; and zip -r gnome.ext.song.title.zip ./gnome.ext.song.title -x "*.git*"'
# abbr ext_enable 'gnome-extensions enable gnome.ext.song.title@jackpts.github.com'
# abbr ext_disable 'gnome-extensions disable gnome.extsong.title@jackpts.github.com'
# abbr ext_go 'cd /home/jacky/.local/share/gnome-shell/extensions/'
# abbr ext_reload 'gnome-extensions disable gnome.extsong.title@jackpts.github.com; and \
# gnome-extensions uninstall gnome.ext.song.title@jackpts.github.com; and \
# z ~/github; and rm gnome.ext.song.title.zip; and zip -r gnome.ext.song.title.zip ./gnome.ext.song.title -x "*.git*"; and \
# gnome-extensions install ./gnome.ext.song.title.zip --force'

# Hyprland and Waybar
abbr h_clients 'hyprctl clients'
abbr h_edit 'nvim ~/.config/hypr/hyprland.conf'
abbr h_waybar 'nvim ~/.config/waybar/config.jsonc'
abbr h_reload 'hyprctl reload'
abbr w_kill 'killall -SIGUSR2 waybar'
abbr w_start 'waybar &'
abbr w_trace 'WAYBAR_LOG_LEVEL=trace waybar'
abbr h_60Hz 'hyprctl keyword monitor eDP-1, 2560x1600@60, auto, 1'
abbr h_165Hz 'hyprctl keyword monitor eDP-1, 2560x1600@165, auto, 1'
abbr h_plugins 'hyprpm list'
abbr h_mons 'ls /sys/class/hwmon/'
abbr h_active_monitor "hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'"
abbr h_default_audio "pactl list sources | grep 'Name' | grep -v 'monitor' | cut -d ' ' -f2"

# Network
abbr wifi_on 'nmcli r wifi on'
abbr wifi_off 'nmcli r wifi off'
abbr wifi_restart 'sudo systemctl restart NetworkManager'
abbr wifi_list 'nmcli dev wifi list'
abbr wifi_status 'nmcli dev status'
abbr wifi_2G 'nmcli dev wifi connect "Andromeda2" --ask'
abbr wifi_5G 'nmcli dev wifi connect "Andromeda5" --ask'
abbr list_x_sessions 'ls /usr/share/xsessions/'
abbr list_w_sessions 'ls /usr/share/wayland-sessions/'
abbr cpu_usage "vmstat 1 2 | tail -1 | awk '{print 100 - \$15\"%\"}'"
abbr opera_wayland 'opera --enable-features=UseOzonePlatform --ozone-platform=wayland'
abbr obsidian_wayland 'obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland'
abbr msty_wayland 'msty --enable-features=UseOzonePlatform --ozone-platform=wayland'
abbr term_theme 'sh $HOME/scripts/update_term_theme.sh'
abbr dot 'cd $HOME/dotfiles'

# SETS-derived abbr
abbr TAR 'tar -zcvf'
abbr UNTAR 'tar -zxvf'

# AI helpers
abbr ol_serve 'OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_ACCELERATE=1 ollama serve'
abbr ai_gemma 'OLLAMA_ACCELERATE=1 aider --model ollama_chat/gemma3'
abbr ai_qwen 'OLLAMA_ACCELERATE=1 aider --model ollama_chat/qwen3'
# warp_cli
abbr warp_cli $HOME/dotfiles/.venv/bin/python $HOME/dotfiles/scripts/warp-cli.py
# Kiro
abbr kiro ELECTRON_OZONE_PLATFORM_HINT=auto $HOME/soft/Kiro/kiro

# Custom aliases
alias bashedit 'nvim ~/.bashrc --allow-root'
alias fishedit 'nvim ~/.config/fish/config.fish'
alias neofetch_edit 'sudo nano ~/.config/neofetch/config.conf'
alias catnap_edit 'nvim ~/.config/catnap/config.toml'
alias alac_edit 'nvim ~/.config/alacritty/alacritty.toml'

alias mirrors_list 'cat /etc/pacman.d/mirrorlist'
alias mirrors_find 'reflector --latest 20 --sort rate --protocol https'
# alias mirrors_update 'sudo reflector --verbose --latest 20 --sort rate --protocol https --timeout 10 --threads 4 --save /etc/pacman.d/mirrorlist'
alias mirrors_update 'sudo reflector --verbose --latest 20 --sort rate --protocol https --threads 4 --save /etc/pacman.d/mirrorlist'
alias list_gnome_extensions 'ls -1 ~/.local/share/gnome-shell/extensions/'
alias show_opened_ports 'lsof -i -P -n | grep LISTEN'
alias pogoda_minsk 'curl -4 https://wttr.in/Minsk'
alias ventoy_update 'sudo ~/soft/ventoy-1.1.05/Ventoy2Disk.sh -u /dev/sda'
alias refind_conf_edit1 'sudo nano /boot/refind_linux.conf'
alias refind_conf_edit2 'sudo nano /boot/EFI/refind/refind.conf'
alias resolution_back 'xrandr -s 2560x1600'
alias ssid_level 'iwconfig wlan0 | gnmcli dev wifi'
alias change_shell_to_bash 'chsh -s /bin/bash'
alias change_shell_to_fish 'chsh -s /usr/bin/fish'
alias docker_mem_usage 'docker stats --no-stream'
alias established 'netstat -anp | grep ESTABLISHED'

# Misc abbr
# abbr backup $HOME/scripts/backup.sh
abbr backup $HOME/dotfiles/scripts/sway-backup.sh
abbr ipinfo 'curl ipinfo.io'
abbr ip 'ip -c'
abbr ipe 'curl ifconfig.co'
abbr ips 'ip link show'
abbr wloff 'rfkill block wlan'
abbr wlon 'rfkill unblock wlan'
abbr network_restart 'sudo systemctl restart NetworkManager; and sudo systemctl restart systemd-resolved; and sudo systemctl restart dhcpcd'
abbr -a -g priv 'fish --private'
abbr -a -g genpass 'openssl rand -base64 10'
abbr pull_fotos 'adb pull /sdcard/DCIM/Camera/ ~/Downloads/'
abbr rs "rsync -avh --progress --exclude 'node_modules'"
abbr sddm_list 'ls -1 /usr/share/sddm/themes'
abbr sddm_edit 'nvim /etc/sddm.conf'
abbr sddm_restart 'sudo systemctl restart sddm'
abbr sddm_theme 'bash $HOME/scripts/sddm_setup_theme.sh'
abbr plym_edit 'nvim /etc/plymouth/plymouthd.conf'
abbr plym_update 'sudo mkinitcpio -P'
abbr plym_theme 'bash $HOME/scripts/plymouth_setup_theme.sh'
abbr init_system 'ps -p 1 -o comm='
abbr kitty_reload 'killall -USR1 kitty'
abbr viber_cc 'rm -rf ~/.ViberPC ~/.cache/Viber\ Media\ S.à\ r.l/ViberPC/'
abbr curl 'curl -#'

# Screen recording helpers
abbr s_r 'gpu-screen-recorder -w screen -f 60 -a (pactl list sources | grep "Name" | grep -v "monitor" | cut -d " " -f2) -o "$HOME/Videos/Screenrecorder/(date +%Y-%m-%d-%H%M%S).mp4"'
abbr rec_sound '$HOME/scripts/screen_record.sh --sound'
abbr rec_fs '$HOME/scripts/screen_record.sh --fullscreen'
abbr rec_fs_sound '$HOME/scripts/screen_record.sh --fullscreen-sound'
abbr rec_selection '$HOME/scripts/screen_record.sh'

# Update helpers
abbr un '$aurhelper -Rns'
abbr u1 'sudo pacman -Suyy'
abbr u2 '$aurhelper -Suyy --noconfirm'

# Tools
# alias yt-mp3 'cd ~/Downloads; and yt-dlp --audio-format mp3 --embed-metadata --audio-quality 0 -x'
# yt-dlp -x --audio-format mp3 --cookies-from-browser chrome "https://www.youtube.com/watch?v=RLPfcG8oVqs"
alias yt-mp3 'cd ~/Downloads; and yt-dlp --audio-format mp3 --cookies-from-browser chrome --embed-metadata --audio-quality 0 -x'

# K8s and misc
alias k 'kubectl'
alias m 'minikube'
# Mining
alias mining_start 'cd ~/soft/NBMiner_Linux; and ./start_eth.sh'
alias edit_miner 'nvim ~/soft/NBMiner_Linux/start_eth.sh'
alias hack_168 'cd /home/jacky/hack; and sudo aircrack-ng -w ./dict/rockyou.txt 68:ff:7b:27:96:cf ./168/clean-168.cap'

# NVIM
abbr n nvim
alias v 'nvim .'
alias vim_plugins 'nvim ~/.config/nvim/lua/plugins/user.lua'
alias vim_log 'nvim ~/.local/state/nvim/lsp.log'
alias vim_startify 'nvim +:Startify'
alias vim-astro "NVIM_APPNAME=AstroNvim nvim"
alias vim-lazy "NVIM_APPNAME=LazyVim nvim"
abbr vim_minimal 'nvim -u NONE'

# SQL
abbr mysql mariadb

# Git helpers
abbr gl 'git log --oneline --graph'
abbr gs 'clear; and git log --graph --stat'
abbr gss 'clear; and git log --stat --color -p'

# Gnome accounts settings run
abbr gnome_accounts 'XDG_CURRENT_DESKTOP=GNOME gnome-control-center online-accounts'

# GitHub login
abbr gh_login 'gh auth login'

# WayVNC connect
abbr way_connect 'wayvnc -C ~/.config/wayvnc/config 0.0.0.0 5900'

# Quickshell run
abbr q_start 'quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"'
abbr q_reload 'quickshell kill -p "$HOME/dotfiles/.config/quickshell/jackbar"; or true; for i in (seq 1 50); quickshell list -p "$HOME/dotfiles/.config/quickshell/jackbar" >/dev/null 2>&1; or break; sleep 0.1; end; quickshell -d -n -p "$HOME/dotfiles/.config/quickshell/jackbar"'
abbr q_reload_dbg 'quickshell kill -p "$HOME/dotfiles/.config/quickshell/jackbar"; or true; for i in (seq 1 50); quickshell list -p "$HOME/dotfiles/.config/quickshell/jackbar" >/dev/null 2>&1; or break; sleep 0.1; end; QS_PANEL_DEBUG=1 quickshell -d -n -p "$HOME/dotfiles/.config/quickshell/jackbar" -vv'

# Mirroring
abbr mir_list 'swaymsg -t get_outputs'
abbr mir_on 'wl-mirror --fullscreen-output HDMI-A-1 --fullscreen eDP-1'
abbr mir_scale 'wl-mirror eDP-1 '
abbr mir_off 'pkill wl-mirror'

# Chrome run in wayland mode
abbr chrome_w 'google-chrome-stable --ozone-platform=wayland'
