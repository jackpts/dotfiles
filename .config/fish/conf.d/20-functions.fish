# 20-functions.fish
# User functions only. Avoid global state; read env set in 00-env.

# Waybar helpers
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

    sed '/@charset "UTF-8";/d' style.css >/tmp/style.css; and mv /tmp/style.css style.css
end

# Archive extractor
function ex
    set -l f $argv[1]
    if test -f "$f"
        switch $f
            case '*.tar.bz2'
                tar xjf -- "$f"
            case '*.tar.gz'
                tar xzf -- "$f"
            case '*.bz2'
                bunzip2 -- "$f"
            case '*.rar'
                unrar x -- "$f"
            case '*.gz'
                gunzip -- "$f"
            case '*.tar'
                tar xf -- "$f"
            case '*.tbz2'
                tar xjf -- "$f"
            case '*.tgz'
                tar xzf -- "$f"
            case '*.zip'
                unzip -- "$f"
            case '*.Z'
                uncompress -- "$f"
            case '*.7z'
                7z x -- "$f"
            case '*'
                echo "'$f' cannot be extracted via ex()"
        end
    else
        echo "'$f' is not a valid file"
    end
end

# Backup helpers
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

# Generic helpers
function write_iso
    # sudo dd if=$argv[1] of=/dev/sda1 bs=4M status=progress conv=fsync
    sudo dd if=$argv[1] of=/dev/sda1 bs=100M conv=fsync
end

function :q
    exit
end

function beep
    # paplay /home/jacky/Music/ringtones/keep-moving_ring.mp3
    play -n synth 0.1 sine 880 vol 0.2
end

# Git clone + cd
function gcl
    set directory (echo $argv | grep -oE '[^/]+$' | sed 's/.git//')
    git clone $argv; and cd $directory
end

function gcld
    set directory (echo $argv | grep -oE '[^/]+$' | sed 's/.git//')
    git clone --depth 1 $argv; and cd $directory
end

# mp4->gif
function mp4_to_gif --argument file
    if not test -e $file
        echo "File $file not found!"
        return 1
    end

    set output (string replace -r '.mp4$' '.gif' $file)

    ffmpeg -i $file -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -c:v pam -f image2pipe - | magick -delay 5 -loop 0 - $output

    echo "Encoding finished: $output"
end

# GIF optimization
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

# Record selection to GIF
function record_selection_to_gif
    set geometry (slurp)
    set width_height (echo $geometry | cut -d'+' -f1)
    set width (echo $width_height | cut -d'x' -f1)
    set height (echo $width_height | cut -d'x' -f2)

    cd $HOME/Videos/Screenrecorder/
    set temp_file "./temp_recording.mp4"
    set output "recording_(date +%Y-%m-%d_%H.%M.%S).gif"

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

# VPN
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

# Directory helpers
function mkcd
    mkdir -p $argv; and cd $argv
end

# Custom cd wrapping zoxide (see 30-integrations for zoxide init)
# function cd
#     if type -q z
#         z $argv
#     else
#         builtin cd $argv
#     end
#     l
# end

