### My Dot Files

- .gitconfig
- TMUX config
- popular terminals config (kitty, alacritty, ghosty)
- neovim config (based on LazyVim)
- fish config (+ a bit of zsh customization)
- hyprland/waybar config

### Install `Hyprland` packages

```bash
    sudo pacman -S --needed hyprland starship swayimg waybar rofi swaync obs-studio jq wl-clipboard libnotify nitrogen copyq figlet gum
    yay -S --needed hyprpicker arch-update hyprwall swaybg grim hyprlock hyprpicker scrot xclip hyprshot brightnessctl hyprpolkitagent hyprsunset hyprsysteminfo hypridle hyprswitch wlogout
```

### Install other packages

```bash
    sudo pacman -S ttf-font-awesome ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-droid ttf-jetbrains-mono ttf-jetbrains-mono-nerd gnome-calendar
    yay -S ttf-cascadia-code-nerd mission-center checkupdates-with-aur paru walker-bin
    paru -S ttf-maple-beta

```

### Install dotfiles using `Stow` & implement configs

```bash
    sudo pacman -S stow
    git clone --depth 1 https://github.com/jackpts/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow fish
    stow tmux
    stow kitty
    stow nvim
    stow hyprland
    stow waybar
    ...
```

### Screenshots

![image](assets/2025-01-13-171759_hyprshot.jpg)

![image](assets/2025-01-13-173201_hyprshot.jpg)

### TODO

- kbd switcher doesn't work by clicking on waybar icon
- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
- LazyGit custom theme add (or set of)
- KDE Connect waybar integration / display battery % of phone-watches?
