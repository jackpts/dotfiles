alias cp='cp -i'
alias df='df -h'
alias free='free -m'
alias cls='clear'
alias la='ls -A'
alias l='ls -alF'
alias ls='eza --color=always --long --git --icons=always'
alias cdi='zi'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias z..='z ..'
alias logmeout="sudo pkill -u $USER"
alias pacman_clean='pacman -Rsn $(pacman -Qdtq)'
alias pacman_clear_cache='sudo paccache -r'
alias gnome_startup='gnome-session-properties'
alias rel_info='cat /etc/*rel*'
alias duf='duf --hide loops,special --sort filesystem'
alias themes='ls /usr/share/themes'

alias logs='journalctl -xe'
alias log_errors='journalctl -p err -b'
alias syslog='sudo dmesg --level=emerg,alert,crit'
alias sys_acpi="sudo dmesg | grep ACPI"

alias gnome_errors='journalctl /usr/bin/gnome-shell -f -o cat'
alias gnome_ver='gnome-shell --version'

alias h_clients='hyprctl clients'
alias h_edit='nvim ~/.config/hypr/hyprland.conf'
alias h_waybar='nvim ~/.config/waybar/config.jsonc'
alias h_reload='hyprctl reload'
alias w_kill='killall -SIGUSR2 waybar'
alias w_start='waybar &'
alias w_trace='WAYBAR_LOG_LEVEL=trace waybar'
alias h_60Hz='hyprctl keyword monitor eDP-1, 2560x1600@60, auto, 1'
alias h_165Hz='hyprctl keyword monitor eDP-1, 2560x1600@165, auto, 1'
alias h_plugins='hyprpm list'
alias h_mons='ls /sys/class/hwmon/'
alias h_active_monitor="hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'"
alias h_default_audio="pactl list sources | grep 'Name' | grep -v 'monitor' | cut -d ' ' -f2"

alias wifi_on='nmcli r wifi on'
alias wifi_off='nmcli r wifi off'
alias wifi_restart='sudo systemctl restart NetworkManager'
alias wifi_list='nmcli dev wifi list'
alias wifi_status='nmcli dev status'
alias wifi_2G='nmcli dev wifi connect "Andromeda2" --ask'
alias wifi_5G='nmcli dev wifi connect "Andromeda5" --ask'
alias list_x_sessions='ls /usr/share/xsessions/'
alias list_w_sessions='ls /usr/share/wayland-sessions/'
alias cpu_usage="vmstat 1 2 | tail -1 | awk '{print 100 - \$15"%"}'"
alias opera_wayland='opera --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias obsidian_wayland='obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias msty_wayland='msty --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias term_theme='sh $HOME/scripts/update_term_theme.sh'
alias dot='cd $HOME/dotfiles && git status'

alias TAR='tar -zcvf'
alias UNTAR='tar -zxvf'

alias ol_serve='OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_ACCELERATE=1 ollama serve'
alias ai_gemma='OLLAMA_ACCELERATE=1 aider --model ollama_chat/gemma3'
alias ai_qwen='OLLAMA_ACCELERATE=1 aider --model ollama_chat/qwen3'
alias warp_cli="$HOME/dotfiles/.venv/bin/python $HOME/dotfiles/scripts/warp-cli.py"
alias kiro='ELECTRON_OZONE_PLATFORM_HINT=auto $HOME/soft/Kiro/kiro'

alias bashedit='nvim ~/.bashrc --allow-root'
alias fishedit='nvim ~/.config/fish/config.fish'
alias neofetch_edit='sudo nano ~/.config/neofetch/config.conf'
alias catnap_edit='nvim ~/.config/catnap/config.toml'
alias alac_edit='nvim ~/.config/alacritty/alacritty.toml'

alias mirrors_list='cat /etc/pacman.d/mirrorlist'
alias mirrors_find='reflector --latest 20 --sort rate --protocol https'
alias mirrors_update='sudo reflector --verbose --latest 20 --sort rate --protocol https --threads 4 --save /etc/pacman.d/mirrorlist'
alias list_gnome_extensions='ls -1 ~/.local/share/gnome-shell/extensions/'
alias show_opened_ports="lsof -i -P -n | grep LISTEN"
alias pogoda_minsk='curl -4 https://wttr.in/Minsk'
alias ventoy_update='sudo ~/soft/ventoy-1.1.05/Ventoy2Disk.sh -u /dev/sda'
alias refind_conf_edit1='sudo nano /boot/refind_linux.conf'
alias refind_conf_edit2='sudo nano /boot/EFI/refind/refind.conf'
alias resolution_back='xrandr -s 2560x1600'
alias ssid_level='iwconfig wlan0 | gnmcli dev wifi'
alias change_shell_to_bash='chsh -s /bin/bash'
alias change_shell_to_fish='chsh -s /usr/bin/fish'
alias docker_mem_usage='docker stats --no-stream'
alias established="netstat -anp | grep ESTABLISHED"

alias backup='$HOME/dotfiles/scripts/sway-backup.sh'
alias ipinfo='curl ipinfo.io'
alias ip='ip -c'
alias ipe='curl ifconfig.co'
alias ips='ip link show'
alias wloff='rfkill block wlan'
alias wlon='rfkill unblock wlan'
network_restart() {
  sudo systemctl restart NetworkManager && sudo systemctl restart systemd-resolved && sudo systemctl restart dhcpcd
}
alias network_restart='network_restart'
alias priv='fish --private'
alias genpass='openssl rand -base64 10'
alias pull_fotos='adb pull /sdcard/DCIM/Camera/ ~/Downloads/'
alias rs="rsync -avh --progress --exclude 'node_modules'"
alias sddm_list='ls -1 /usr/share/sddm/themes'
alias sddm_edit='nvim /etc/sddm.conf'
alias sddm_restart='sudo systemctl restart sddm'
alias sddm_theme='bash $HOME/scripts/sddm_setup_theme.sh'
alias plym_edit='nvim /etc/plymouth/plymouthd.conf'
alias plym_update='sudo mkinitcpio -P'
alias plym_theme='bash $HOME/scripts/plymouth_setup_theme.sh'
alias init_system='ps -p 1 -o comm='
alias kitty_reload='killall -USR1 kitty'
alias viber_cc='rm -rf ~/.ViberPC ~/.cache/Viber\ Media\ S.à\ r.l/ViberPC/'
alias curl='curl -#'

s_r() {
  local src
  src="$(pactl list sources | grep "Name" | grep -v "monitor" | cut -d " " -f2 | head -n1)"
  gpu-screen-recorder -w screen -f 60 -a "$src" -o "$HOME/Videos/Screenrecorder/$(date +%Y-%m-%d-%H%M%S).mp4"
}
alias s_r='s_r'

alias rec_sound='$HOME/scripts/screen_record.sh --sound'
alias rec_fs='$HOME/scripts/screen_record.sh --fullscreen'
alias rec_fs_sound='$HOME/scripts/screen_record.sh --fullscreen-sound'
alias rec_selection='$HOME/scripts/screen_record.sh'

alias u1='sudo pacman -Suyy'

alias k='kubectl'
alias m='minikube'

alias mining_start='cd ~/soft/NBMiner_Linux && ./start_eth.sh'
alias edit_miner='nvim ~/soft/NBMiner_Linux/start_eth.sh'
alias hack_168='cd /home/jacky/hack && sudo aircrack-ng -w ./dict/rockyou.txt 68:ff:7b:27:96:cf ./168/clean-168.cap'

alias n='nvim'
alias v='nvim .'
alias vim_plugins='nvim ~/.config/nvim/lua/plugins/user.lua'
alias vim_log='nvim ~/.local/state/nvim/lsp.log'
alias vim_startify='nvim +:Startify'
alias vim-astro='NVIM_APPNAME=AstroNvim nvim'
alias vim-lazy='NVIM_APPNAME=LazyVim nvim'
alias vim_minimal='nvim -u NONE'

alias mysql='mariadb'

alias gl='git log --oneline --graph'
alias gs='clear && git log --graph --stat'
alias gss='clear && git log --stat --color -p'

alias gnome_accounts='XDG_CURRENT_DESKTOP=GNOME gnome-control-center online-accounts'
alias gh_login='gh auth login'
alias way_connect='wayvnc -C ~/.config/wayvnc/config 0.0.0.0 5900'

alias mir_list='swaymsg -t get_outputs'
alias mir_on='wl-mirror --fullscreen-output HDMI-A-1 --fullscreen eDP-1'
alias mir_scale='wl-mirror eDP-1 '
alias mir_off='pkill wl-mirror'

alias chrome_w='google-chrome-stable --ozone-platform=wayland'
