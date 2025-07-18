if status is-interactive
    # Commands to run in interactive sessions can go here
end

### theme
# set -g theme_display_git yes
# set -g theme_display_git_untracked yes
# set -g theme_display_git_master_branch yes
# set -g theme_title_use_abbreviated_path no
# set -g fish_prompt_pwd_dir_length 0
# set -g theme_project_dir_length 0
# set -g theme_newline_cursor yes

### NVM
# bash /usr/share/nvm/init-nvm.sh
# export NVM_DIR="$(printf %s "$HOME/.nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

### pnpm
set -gx PNPM_HOME "/home/jacky/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

### Proton
export WLR_BACKEND=vulkan
export __VK_LAYER_NV_optimus=NVIDIA_only
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export MESA_LOADER_DRIVER_OVERRIDE=zink

### BASE ALIASES
alias cp="cp -i"
alias df='df -h'
alias free='free -m'
alias qq='notepadqq $1 --allow-root'
alias cls='clear'
alias la='ls -A'
alias l='ls -alF'
alias cd..='cd ..'
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr ... 'cd ../../..'
abbr mkdir 'mkdir -p'
alias z..='z ..'
alias logmeout='sudo pkill -u jacky'
alias pacman_clean='pacman -Rsn $(pacman -Qdtq)'
alias pacman_clear_cache='sudo paccache -r'
alias gnome_startup='gnome-session-properties'
alias rel_info='cat /etc/*rel*'
abbr duf 'duf --hide loops,special --sort filesystem'
abbr themes 'ls /usr/share/themes'

### Errors
abbr logs 'journalctl -xe'
abbr syslog 'sudo dmesg --level=emerg,alert,crit'
abbr sys_acpi 'sudo dmesg | grep ACPI'

### Gnome shell
abbr gnome_errors 'journalctl /usr/bin/gnome-shell -f -o cat'
abbr gnome_ver 'gnome-shell --version'
# abbr ext_create 'gnome-extensions create --interactive'
# abbr ext_list 'gnome-extensions list | grep jack'
# abbr ext_edit 'nvim ~/github/gnome.ext.song.title/extension.js'
# abbr ext_install 'gnome-extensions install ./gnome.ext.song.title.zip --force'
# abbr ext_remove 'gnome-extensions uninstall gnome.ext.song.title@jackpts.github.com'
# abbr ext_pack 'z ~/github && rm gnome.ext.song.title.zip && zip -r gnome.ext.song.title.zip ./gnome.ext.song.title -x "*.git*"'
# abbr ext_enable 'gnome-extensions enable gnome.ext.song.title@jackpts.github.com'
# abbr ext_disable 'gnome-extensions disable gnome.extsong.title@jackpts.github.com'
# abbr ext_go 'cd /home/jacky/.local/share/gnome-shell/extensions/'
# abbr ext_reload 'gnome-extensions disable gnome.extsong.title@jackpts.github.com && \
# gnome-extensions uninstall gnome.ext.song.title@jackpts.github.com && \
# z ~/github && rm gnome.ext.song.title.zip && zip -r gnome.ext.song.title.zip ./gnome.ext.song.title -x "*.git*" && \
# gnome-extensions install ./gnome.ext.song.title.zip --force
# '

### Hyprland
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

function w_toggle
    if pgrep -x waybar >/dev/null
        pkill waybar
    else
        WAYBAR_LOG_LEVEL=trace waybar
    end
end

function w_styles
    cd "$HOME/dotfiles/.config/waybar"
    sass style.scss style.css

    sed '/@charset "UTF-8";/d' style.css >/tmp/style.css && mv /tmp/style.css style.css
end

### SETS
set HISTSIZE -1 # Infinte history
set HISTFILESIZE -1 # Infinte history
set HISTCONTROL ignoreboth # Don't save duplicate commands or commands starting with space
set -U -x TERMINAL kitty
set -U XDG_DATA_HOME $HOME/.local/share

# For Opencode:
# set LOCAL_ENDPOINT http://localhost:1234/v1
# export LOCAL_ENDPOINT="http://localhost:1234/v1"
# export BASE_URL="http://localhost:1234/v1"

# For Aider:
export OLLAMA_API_BASE=http://127.0.0.1:11434
abbr ol_serve OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_ACCELERATE=1 ollama serve
abbr ai_gemma OLLAMA_ACCELERATE=1 aider --model ollama_chat/gemma3
abbr ai_qwen OLLAMA_ACCELERATE=1 aider --model ollama_chat/qwen3
export AIDER_DARK_MODE=true

# Wayland
set -gx MOZ_ENABLE_WAYLAND 1
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND wayland

# Fix error: X11Helper-WARNING **: 01:47:27.455: Failed to open display: :1
# echo $DISPLAY
# :1
# set -e DISPLAY
# set -gx DISPLAY eDP-1
set -gx DISPLAY $WAYLAND_DISPLAY

### EXPORTS
export VISUAL='nvim'
export EDITOR="$VISUAL"
export TERMINAL='kitty'
export BROWSER='zen'
export PATH="$PATH:/opt/nvim-linux64/bin"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export TERM_EMULATOR='kitty'
export TERM='xterm-kitty'
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
export MANPAGER='nvim +Man!'

### MY CUSTOM ALIASES
alias bashedit='nvim ~/.bashrc --allow-root'
alias fishedit='nvim ~/.config/fish/config.fish'
alias neofetch_edit='sudo nano ~/.config/neofetch/config.conf'
alias catnap_edit='nvim ~/.config/catnap/config.toml'
alias alac_edit='nvim ~/.config/alacritty/alacritty.toml'

alias mirrors_list='cat /etc/pacman.d/mirrorlist'
alias mirrors_find='reflector --latest 20 --sort rate --protocol https'
# alias mirrors_update='sudo reflector --verbose --latest 20 --sort rate --protocol https --timeout 10 --threads 4 --save /etc/pacman.d/mirrorlist'
alias mirrors_update='sudo reflector --verbose --latest 20 --sort rate --protocol https --threads 4 --save /etc/pacman.d/mirrorlist'
alias list_gnome_extensions='ls -1 ~/.local/share/gnome-shell/extensions/'
alias show_opened_ports='lsof -i -P -n | grep LISTEN'
alias pogoda_minsk='curl -4 https://wttr.in/Minsk'
alias ventoy_update='sudo ~/soft/ventoy-1.1.05/Ventoy2Disk.sh -u /dev/sda'
alias refind_conf_edit1='sudo nano /boot/refind_linux.conf'
alias refind_conf_edit2='sudo nano /boot/EFI/refind/refind.conf'
alias resolution_back='xrandr -s 2560x1600'
alias ssid_level='iwconfig wlan0 | gnmcli dev wifi'
alias change_shell_to_bash='chsh -s /bin/bash'
alias change_shell_to_fish='chsh -s /usr/bin/fish'
alias docker_mem_usage='docker stats --no-stream'
alias established='netstat -anp | grep ESTABLISHED'
abbr ipinfo 'curl ipinfo.io'
abbr ip 'ip -c'
abbr ipe 'curl ifconfig.co'
abbr ips 'ip link show'
abbr wloff 'rfkill block wlan'
abbr wlon 'rfkill unblock wlan'
abbr network_restart 'sudo systemctl restart NetworkManager && sudo systemctl restart systemd-resolved && sudo systemctl restart dhcpcd'
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

# CLI Screenrecorder
abbr s_r 'gpu-screen-recorder -w screen -f 60 -a $(pactl list sources | grep "Name" | grep -v "monitor" | cut -d " " -f2) -o "$HOME/Videos/Screenrecorder/$(date +%Y-%m-%d-%H%M%S).mp4"'
abbr rec_sound '$HOME/scripts/screen_record.sh --sound'
abbr rec_fs '$HOME/scripts/screen_record.sh --fullscreen'
abbr rec_fs_sound '$HOME/scripts/screen_record.sh --fullscreen-sound'
abbr rec_selection '$HOME/scripts/screen_record.sh'

# update helpers
abbr un '$aurhelper -Rns'
abbr u1 'sudo pacman -Suyy'
abbr u2 '$aurhelper -Suyy --noconfirm'

### VPN
function proton_vpn
    cd ~/vpn/proton/

    # regular options: nl | jp | us
    if test (count $argv) -gt 0
        set file_prefix "$argv[1]"
    else
        set file_prefix ''
    end

    set cur_vpn_file (find -name "$file_prefix*.ovpn" -type f -exec ls -lt {} + | sort -k6,7 | head -n1 | awk '{print $NF}')
    echo "VPN file used: $cur_vpn_file"
    sudo openvpn --config $cur_vpn_file --auth-user-pass pass.txt
end

### Tools
alias yt-mp3='cd ~/Downloads && yt-dlp --audio-format mp3 --embed-metadata --audio-quality 0 -x'

### FUNCTIONS

# function ll
# clear;
# tput cup 0 0;
# ls --color=auto -F --color=always -lhFrt $1;
# tput cup 40 0;
# end

function ex
    if [ -f $1 ]
        then
        switch $1
            case *.tar.bz2
                tar xjf $1
            case *.tar.gz
                tar xzf $1
            case *.bz2
                bunzip2 $1
            case *.rar
                unrar x $1
            case *.gz
                gunzip $1
            case *.tar
                tar xf $1
            case *.tbz2
                tar xjf $1
            case *.tgz
                tar xzf $1
            case *.zip
                unzip $1
            case *.Z
                uncompress $1
            case *.7z
                7z x $1
            case '*'
                echo "'$1' cannot be extracted via ex()"
        end
    else
        echo "'$1' is not a valid file"
    end
end

abbr TAR 'tar -zcvf'
abbr UNTAR 'tar -zxvf'

abbr backup $HOME/scripts/backup.sh

function backup_git
    set cur_Date (date +"%d%b-%H")
    set outputDir /run/media/jacky/back2up/regular

    sudo 7z u -bt $outputDir/git-$cur_Date.7z -spf2 -mx7 /home/jacky/git -xr!node_modules -xr!_others -xr!wpa2-wordlists '-xr!*.7z' '-xr!*.dump' '-xr!*.pack'
end

function backup_job
    set cur_Date (date +"%d%b-%H")
    set outputDir /run/media/jacky/back2up/regular

    sudo 7z u -bt $outputDir/jobs-$cur_Date.7z -spf2 -mx7 /home/jacky/Documents/CV /home/jacky/Documents/jobs/ /home/jacky/Documents/MyCerts
end

function backup_nvim
    set cur_Date (date +"%d%b-%H")
    set outputDir /run/media/jacky/back2up/regular

    sudo 7z u -bt $outputDir/nvim-$cur_Date.7z -spf2 -mx7 /home/jacky/.config/nvim /home/jacky/.local/share/nvim /home/jacky/.local/state/nvim /home/jacky/.cache/nvim
end

function write_iso
    # sudo dd if=$1 of=/dev/sda1 bs=4M status=progress conv=fsync
    sudo dd if=$1 of=/dev/sda1 bs=100M conv=fsync
end

# K8Ns
alias k='kubectl'
alias m='minikube'

# Mining
alias mining_start='cd ~/soft/NBMiner_Linux && ./start_eth.sh'
alias edit_miner='nvim ~/soft/NBMiner_Linux/start_eth.sh'

# NVIM
abbr n nvim
alias v "nvim ."
alias vim_plugins='nvim ~/.config/nvim/lua/plugins/user.lua'
alias vim_log='nvim ~/.local/state/nvim/lsp.log'
alias vim_startify='nvim +:Startify'
alias vim-astro="NVIM_APPNAME=AstroNvim nvim"
alias vim-lazy="NVIM_APPNAME=LazyVim nvim"
abbr vim_minimal nvim -u NONE

function :q
    exit
end

### hack
alias hack_168='cd /home/jacky/hack && sudo aircrack-ng -w ./dict/rockyou.txt 68:ff:7b:27:96:cf ./168/clean-168.cap'

function beep
    # paplay /home/jacky/Music/ringtones/keep-moving_ring.mp3
    play -n synth 0.1 sine 880 vol 0.2
end

### git
abbr gl 'git log --oneline --graph'
abbr gs 'clear && git log --graph --stat'
abbr gss 'clear && git log --stat --color -p'

function gcl
    set directory (echo $argv | grep -oE '[^/]+$' | sed 's/.git//')
    git clone $argv && cd $directory
end

function gcld
    set directory (echo $argv | grep -oE '[^/]+$' | sed 's/.git//')
    git clone --depth 1 $argv && cd $directory
end

### FZF
fzf --fish | source

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

function _fzf_compgen_path
    fd --hidden --exclude .git . $1
end

function _fzf_comprun
    local command=$1
    shift

    switch $command
        case cd
            fzf --preview 'eza --tree --color=always {} | head -200' $argv
        case ssh
            fzf --preview "eval 'echo \$' {}" $argv
        case '*'
            fzf --preview "--preview 'bat -n --color=always --line-range :500 {}'" $argv
    end
end

alias ls="eza --color=always --long --git --icons=always"
# alias lll='eza -la --git'
alias cdi='zi'

function cd
    # builtin cd $argv
    z $argv
    l
end

function mkcd
    mkdir -p $argv && cd $argv
end

# SQL
abbr mysql mariadb

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null
    set aurhelper yay
end
if pacman -Qi paru &>/dev/null
    set aurhelper paru
end

# install `ffmpeg` before!
# `sudo pacman -S ffmpeg`
function mp4_to_gif --argument file
    if not test -e $file
        echo "File $file not found!"
        return 1
    end

    set output (string replace -r '.mp4$' '.gif' $file)

    ffmpeg -i $file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -c:v pam -f image2pipe - | magick -delay 5 -loop 0 - $output

    echo "Encoding finished: $output"
end

# install `gifsicle` before!
# `sudo pacman -S gifsicle`
function optimize_gif --argument file
    if not test -e $file
        echo "File $file not found!"
        return 1
    end

    set output (string replace -r '.gif$' '_optimized.gif' $file)
    set temp_file "./temp_recording.mp4"

    if test -e $temp_file
        # unique palette colors calc
        ffmpeg -i $temp_file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos,palettegen" -y /tmp/palette.png
        set num_colors (magick $file -unique-colors txt:- | wc -l)

        if test $num_colors -lt 256
            gifsicle -O3 $file -o $output --colors $num_colors
        else
            gifsicle -O3 $file -o $output --colors 256
        end

        rm $temp_file
    else
        gifsicle -O3 $file -o $output --colors 256
    end

    echo "Optimization finished: $output"
end

function record_selection_to_gif
    set geometry (slurp)
    set width_height (echo $geometry | cut -d'+' -f1)
    set width (echo $width_height | cut -d'x' -f1)
    set height (echo $width_height | cut -d'x' -f2)

    cd $HOME/Videos/Screenrecorder/
    set temp_file "./temp_recording.mp4"
    set output "recording_$(date +%Y-%m-%d_%H.%M.%S).gif"

    if test -e $temp_file
        rm $temp_file
    end

    wf-recorder --pixel-format yuv420p -f $temp_file -g $geometry

    if test -e $temp_file
        ffmpeg -i $temp_file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -f gif $output

        # rm $temp_file
        echo "Record finished: $output"
    else
        echo "Error: Temp file not found!"
    end
end

# Make Volta available at the start of PATH
fish_add_path ~/.volta/bin

##################
### FINAL RUN ###
#################

# set -U fish_greeting
# set -U fish_greeting "Weather update: $(curl -s 'wttr.in?format=%C+%t')"
set -U fish_greeting "Welcome, $(whoami), to Fish Shell on $(uname -n) running $(uname -o) $(uname -r)"

fish_vi_key_bindings

# neofetch --colors 3 4 5 6 2 9 &&
# duf --hide special &&
# cowfortune
# fastfetch
# catnap -d kali
# rxfetch

if status is-interactive
    if not set -q __NEOFETCH_STARTED
        set -gx __NEOFETCH_STARTED 1
        neofetch
    end
end

zoxide init fish | source
# starship init fish | source
