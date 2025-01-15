### My Dot Files

- .gitconfig
- TMUX config
- alacritty config
- neovim config (based on LazyVim)
- fish config
- hyprland config

#### Hyprland pre-install packages

```bash
    sudo pacman -S --needed hyprland starship swayimg waybar rofi swaync obs-studio jq wl-clipboard libnotify nitrogen copyq figlet gum
    yay -S --needed hyprpicker arch-update hyprwall swaybg grim hyprlock hyprpicker scrot xclip hyprshot brightnessctl hyprpolkitagent hyprsunset hyprsysteminfo hypridle hyprswitch wlogout
```

### Total system used packages

```bash
    sudo pacman -S ttf-font-awesome
    yay -S ttf-cascadia-code-nerd mission-center checkupdates-with-aur
    paru -S ttf-maple-beta

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
- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
- `notify-send` doesn't look good, bad tooltip text alignment (swaync config changes)
- LazyGit custom theme add (or set of)
- KDE Connect waybar integration?
