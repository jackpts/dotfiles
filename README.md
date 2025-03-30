[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=30&letterSpacing=tiny&duration=2000&pause=10000&color=F7F7F7&center=true&vCenter=true&width=435&lines=JackPts's+Dotfiles)](https://git.io/typing-svg)

- .gitconfig
- TMUX config
- popular terminals config (kitty, alacritty, ghostty)
- neovim config (based on LazyVim)
- fish config (+ a bit of zsh customization)
- hyprland/waybar config

<br />
<details close>
<summary>Paru Installation</summary>

```sh
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
```
</details>

### Install `Hyprland` packages

```bash
    sudo pacman -S --needed hyprland swayimg waybar rofi swaync obs-studio jq wl-clipboard libnotify copyq figlet gum xdg-desktop-portal xdg-desktop-portal-hyprland
    paru -S --needed hyprpicker arch-update hyprwall swaybg hyprlock hyprpicker scrot xclip hyprshot brightnessctl hyprpolkitagent hyprsunset hyprsysteminfo hypridle hyprswitch nwg-dock-hyprland swww waypaper walker-bin
```

### Install related packages

```bash
    sudo pacman -S ttf-font-awesome ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-droid ttf-jetbrains-mono ttf-jetbrains-mono-nerd gnome-calendar mpd ncmpcpp networkmanager-dmenu brightnessctl ttf-firacode-nerd kdeconnect fastfetch neofetch curl nushell starship tmux cmatrix cowfortune power-profiles-daemon mpv
    paru -S ttf-cascadia-code-nerd mission-center resources checkupdates-with-aur ghostty rxfetch ttf-material-design-icons ttf-maple-beta chafa wf-recorder
```

<br />
<details close>
<summary>Hyprshot GUI Installation</summary>

```sh
    git clone https://github.com/s-adi-dev/hyprshot-gui.git
    cd hyprshot-gui
    ./install.sh
```
</details>

### Install dotfiles using `Stow` & implement configs

```bash
    sudo pacman -S stow
    git clone --depth 1 https://github.com/jackpts/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow .
```

### Change screen resolution & refresh rate in `hyprland.conf` to your own:
```conf
# monitor=,preferred,auto,1
monitor = eDP-1, 2560x1600@165, auto, 1
```

### SDDM Themify

```bash
    bash $HOME/scripts/sddm_setup_theme.sh
```

### Plymouth Themify

```bash
    sudo mkdir /usr/share/plymouth/themes/
    sudo pacman -S plymouth
    git clone https://github.com/MrVivekRajan/Plymouth-Themes.git
    cd Plymouth-Themes
    sudo cp -vr {Deadlight,Ironman,Starlord,Anonymous} /usr/share/plymouth/themes/
    bash $HOME/scripts/plymouth_setup_theme.sh
```

<br />
<details close>
<summary>Screenshots</summary>
    <p align="center">
        <img src="assets/2025-01-13-171759_hyprshot.jpg" />
        <br />
        <img src="assets/2025-01-13-173201_hyprshot.jpg" />
        <br />
        <img src="assets/lock_screen.jpg" />
    </p>
</details>
<br />

### TODO

- kbd switcher doesn't work by clicking on waybar icon
- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
- set bar & widgets by `fabric` framework (best python replacement of eww/ags tools). Examples: <https://github.com/Fabric-Development/fabric/tree/main/examples>
- make left sidebar with "AI chat integration with external providers (Gemini, OpenAI...)" like in: <https://www.reddit.com/r/unixporn/comments/1im22sn/hyprland_yet_another_hyprland_rice/>
- move from `systemd` to `runit` ? (like here: <https://www.reddit.com/r/unixporn/comments/1j0w0id/swayfx_my_first_rice/#lightbox>)
- try `home-manager` as a nvim plugin manager:
```sh
    paru -S nix

# in fish/zsh add: `. /etc/profile.d/nix.sh`

    sudo systemctl start nix-daemon
    sudo systemctl enable nix-daemon


    nix-channel --add https://github.com/nix-community/home-manager/archive/release-24_05.tar.gz home-manager
    nix-channel --update
    nix-shell -p home-manager --run "home-manager switch"

    touch ~/.config/nixpkgs/home.nix
    ...

    home-manager switch
```
- add S23 mount function for fish shell
