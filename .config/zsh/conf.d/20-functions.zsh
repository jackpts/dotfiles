w_toggle() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill waybar
  else
    WAYBAR_LOG_LEVEL=trace waybar
  fi
}

w_styles() {
  cd "$HOME/dotfiles/.config/waybar" || return
  sass style.scss style.css
  sed '/@charset "UTF-8";/d' style.css >/tmp/style.css && mv /tmp/style.css style.css
}

ex() {
  local f="$1"
  [[ -f "$f" ]] || { echo "'$f' is not a valid file"; return 1; }
  case "$f" in
    *.tar.bz2) tar xjf -- "$f" ;;
    *.tar.gz)  tar xzf -- "$f" ;;
    *.bz2)     bunzip2 -- "$f" ;;
    *.rar)     unrar x -- "$f" ;;
    *.gz)      gunzip -- "$f" ;;
    *.tar)     tar xf -- "$f" ;;
    *.tbz2)    tar xjf -- "$f" ;;
    *.tgz)     tar xzf -- "$f" ;;
    *.zip)     unzip -- "$f" ;;
    *.Z)       uncompress -- "$f" ;;
    *.7z)      7z x -- "$f" ;;
    *)         echo "'$f' cannot be extracted via ex()"; return 2 ;;
  esac
}

backup_git() {
  local cur_Date
  cur_Date="$(date +"%d%b-%H")"
  local outputDir="/run/media/jacky/back2up/regular"
  sudo 7z u -bt "$outputDir/git-$cur_Date.7z" -spf2 -mx7 /home/jacky/git -xr'!node_modules' -xr'!_others' -xr'!wpa2-wordlists' -xr'!*.7z' -xr'!*.dump' -xr'!*.pack'
}

backup_job() {
  local cur_Date
  cur_Date="$(date +"%d%b-%H")"
  local outputDir="/run/media/jacky/back2up/regular"
  sudo 7z u -bt "$outputDir/jobs-$cur_Date.7z" -spf2 -mx7 /home/jacky/Documents/CV /home/jacky/Documents/jobs/ /home/jacky/Documents/MyCerts
}

backup_nvim() {
  local cur_Date
  cur_Date="$(date +"%d%b-%H")"
  local outputDir="/run/media/jacky/back2up/regular"
  sudo 7z u -bt "$outputDir/nvim-$cur_Date.7z" -spf2 -mx7 /home/jacky/.config/nvim /home/jacky/.local/share/nvim /home/jacky/.local/state/nvim /home/jacky/.cache/nvim
}

write_iso() {
  sudo dd if="$1" of=/dev/sda1 bs=100M conv=fsync
}

:q() {
  exit
}

beep() {
  play -n synth 0.1 sine 880 vol 0.2
}

gcl() {
  local directory
  directory="$(echo "$*" | grep -oE '[^/]+$' | sed 's/.git//')"
  git clone "$@" && cd "$directory"
}

gcld() {
  local directory
  directory="$(echo "$*" | grep -oE '[^/]+$' | sed 's/.git//')"
  git clone --depth 1 "$@" && cd "$directory"
}

mp4_to_gif() {
  local file="$1"
  [[ -e "$file" ]] || { echo "File $file not found!"; return 1; }
  local output
  output="${file%.mp4}.gif"
  ffmpeg -i "$file" -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -c:v pam -f image2pipe - | magick -delay 5 -loop 0 - "$output"
  echo "Encoding finished: $output"
}

optimize_gif() {
  local file="$1"
  [[ -e "$file" ]] || { echo "File $file not found!"; return 1; }
  local output="${file%.gif}_optimized.gif"
  local temp_file="./temp_recording.mp4"

  if [[ -e "$temp_file" ]]; then
    ffmpeg -i "$temp_file" -vf "fps=10,scale=iw/2:ih/2:flags=lanczos,palettegen" -y /tmp/palette.png
    local num_colors
    num_colors="$(magick "$file" -unique-colors txt:- | wc -l)"

    if [[ "$num_colors" -lt 256 ]]; then
      gifsicle -O3 "$file" -o "$output" --colors "$num_colors"
    else
      gifsicle -O3 "$file" -o "$output" --colors 256
    fi

    rm -f "$temp_file"
  else
    gifsicle -O3 "$file" -o "$output" --colors 256
  fi

  echo "Optimization finished: $output"
}

record_selection_to_gif() {
  local geometry
  geometry="$(slurp)" || return 1

  cd "$HOME/Videos/Screenrecorder/" || return
  local temp_file="./temp_recording.mp4"
  local output="recording_$(date +%Y-%m-%d_%H.%M.%S).gif"

  [[ -e "$temp_file" ]] && rm -f "$temp_file"

  wf-recorder --pixel-format yuv420p -f "$temp_file" -g "$geometry"

  if [[ -e "$temp_file" ]]; then
    ffmpeg -i "$temp_file" -vf "fps=10,scale=iw/2:ih/2:flags=lanczos" -f gif "$output"
    echo "Record finished: $output"
  else
    echo "Error: Temp file not found!"
    return 1
  fi
}

proton_vpn() {
  cd "$HOME/vpn/proton/" || return

  local file_prefix="${1:-}"
  local cur_vpn_file
  cur_vpn_file="$(find . -name "${file_prefix}*.ovpn" -type f -exec ls -lt {} + | sort -k6,7 | head -n1 | awk '{print $NF}')"
  echo "VPN file used: $cur_vpn_file"
  sudo openvpn --config "$cur_vpn_file" --auth-user-pass pass.txt
}

mkcd() {
  mkdir -p "$@" && cd "$@"
}

if [[ -o interactive ]]; then
  cd() {
    if (( $+functions[z] )); then
      z "$@"
      ls
    else
      builtin cd "$@" && ls
    fi
  }
fi

plz() {
  if [[ "$#" -gt 0 ]]; then
    sudo "$@"
    return
  fi

  local last_cmd
  last_cmd="$(fc -ln -1)"
  [[ -n "$last_cmd" ]] || { echo "No previous command in history." >&2; return 1; }

  local safe_commands=(apt pacman systemctl journalctl ls lsd cat bat grep find cp mv mkdir rm touch chmod chown npm node yarn pnpm)
  local cmd
  cmd="${last_cmd%% *}"

  local ok=0
  local c
  for c in "${safe_commands[@]}"; do
    [[ "$c" == "$cmd" ]] && ok=1 && break
  done

  if [[ "$ok" -eq 1 ]]; then
    echo "Re-running with sudo: $last_cmd"
    eval "sudo $last_cmd"
  else
    echo "Refusing to sudo: '$last_cmd' (not in safe list)" >&2
    echo "Allowed commands: ${safe_commands[*]}" >&2
    return 1
  fi
}
