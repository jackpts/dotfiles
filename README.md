[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=30&letterSpacing=tiny&duration=2000&pause=10000&color=F7F7F7&center=true&vCenter=true&width=435&lines=JackPts's+Dotfiles)](https://git.io/typing-svg)

- .gitconfig
- TMUX config
- popular terminals config (kitty, alacritty, ghostty)
- neovim config (based on LazyVim)
- fish config (+ a bit of zsh customization)
- hyprland/waybar config
- Zed editor config (+ extensions)

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
    paru -S --needed hyprpicker arch-update hyprwall swaybg mpvpaper hyprpicker scrot xclip hyprshot brightnessctl hyprpolkitagent hyprsunset hyprsysteminfo hypridle hyprswitch nwg-dock-hyprland swaylock-effects swww waypaper walker-bin
```

### Install related packages

```bash
    sudo pacman -S ttf-font-awesome ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-droid ttf-jetbrains-mono ttf-jetbrains-mono-nerd gnome-calendar mpd ncmpcpp networkmanager-dmenu brightnessctl ttf-firacode-nerd kdeconnect fastfetch neofetch curl nushell starship tmux cmatrix cowfortune power-profiles-daemon mpv sass dysk
    paru -S ttf-cascadia-code-nerd mission-center resources checkupdates-with-aur warp-terminal-bin rxfetch ttf-material-design-icons ttf-maple-beta chafa wf-recorder python-pywal
```

### Sway screensaver (asciiquarium overlay)

Sway uses `~/dotfiles/scripts/asciiquarium_lock.sh` for both manual (`$mod+L`) and idle triggers. Install the ASCII aquarium dependency first (kitty is already covered in the terminal section, but is required):

```bash
    sudo pacman -S asciiquarium
```

When either dependency is missing, the shortcut simply notifies you and exits—no traditional lock screen is launched.

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

If error occured with conflicting configs (hyprland, fish, etc.), then stow like this:

```bash
    stow . --adopt
    git stash
```

### Remove all `Stow` configuration symlinks

```bash
    stow -D .
```

### Change screen resolution & refresh rate in `$HOME/dotfiles/.config/hypr/hyprland.conf` to your own:

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
        <img src="assets/quickshell_2025-11-21_15-54-53.jpg" />
        <br />
        <img src="assets/quickshell_2025-12-03_11-40-23.jpg" />
        <br />
        <img src="assets/lock_screen.jpg" />
        <br />
        <img src="assets/sway_quickshell_2026-03-11.jpg" />
    </p>
</details>
<br />

### Zed Editor

Install Zed extensions and MCP servers from dotfiles:

```bash
    ./scripts/install-zed-extensions.sh
```

Configuration files:
- `.config/zed/extensions.json` - Installed extensions (syntax highlighting, languages)
- `.config/zed/servers.json` - MCP context servers and AI agent servers

### Terminals Themify

- use the fish `term_theme` abbr in your current terminal or type `wal -i <wallpaper_path>` directly

### Backup

Run the backup script manually or wait for auto-start on Sway login:

```bash
    ./scripts/sway-backup.sh
```

**Auto-start:** The backup runs automatically 20 seconds after Sway starts (configured in `.config/sway/config`).

**Notification:** After completion, a desktop notification shows:
- Backup file name
- Archive size

**yt-tg-chat-bot:** Auto-starts in kitty terminal on workspace 2 (25 second delay).

This creates backups of:
- Pacman packages (official + AUR)
- Flatpak packages
- GNOME extensions (commented out - not using GNOME)
- **Zed editor extensions**
- **Zen browser**: extensions, bookmarks, session (tabs/workspaces)
- Nemo dconf settings
- System configs (/etc/, dotfiles, SSH, GPG, etc.)
- MySQL dump (commented out temporarily)
- System themes rsync (commented out temporarily)

**Configuration:**
- Output: `/run/media/jacky/back2up/regular/`
- Password: (see `scripts/sway-backup.sh`, `BACKUP_PASSWORD` variable)
- Compression: Maximum (7z -mx=9)
- Archive format: Encrypted 7zip


### Waybar styling

1) use ./.config/waybar/style.scss file
2)  after making changes:
    a)
- convert it to CSS file:
```
    sass style.scss style.css
```
- then go to new CSS file and remove the 1st line: `@charset "UTF-8"`
OR:
    b) run fish function: `w_styles`


### TODO

- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
- make left sidebar with "AI chat integration with external providers (Gemini, OpenAI...)" like in: <https://www.reddit.com/r/unixporn/comments/1im22sn/hyprland_yet_another_hyprland_rice/>
