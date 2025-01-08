### My Dot Files

- .gitconfig
- TMUX config
- alacritty config
- neovim config (based on LazyVim)
- fish config
- hyprland config

#### Hyprland pre-install packages

```bash
    sudo pacman -S --needed hyprland starship swayimg waybar rofi swaync obs-studio dunst jq wl-clipboard libnotify nitrogen copyq
    yay -S --needed hyprpicker wlogout arch-update hyprwall swaybg swaylock grim slurp hyprlock hyprpicker scrot xclip hyprshot brightnessctl hyprpolkitagent hyprsunset hyprsysteminfo hypridle hyprswitch
```

### Total system used packages

```bash
    sudo pacman -S ttf-font-awesome
    yay -S ttf-cascadia-code-nerd

```

### TODO: Move to .dotfiles using Stow

```bash
    sudo pacman -S stow
    git clone --depth 1 <repo_url> ~/.dotfiles
    cd ~/.dotfiles
    stow kitty
    stow nvim
    stow hyprland
    stow waybar
    ...
```

### TODO: fixes

### TODO

- kbd switcher doesn't work by clicking on waybar icon
- add/test Walker launcher instead of WOFI/ROFI ones
- move to .dotfiles (instead of $HOME now) + `stow` logic
- free space home: diff icons (red when free < 10Gb)
- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
- disable tray, move copyq from tray to waybar icon
- `notify-send` doesn't look good, bad tooltip text alignment
- LazyGit custom theme add (or set of)
