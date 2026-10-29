[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=30&letterSpacing=tiny&duration=2000&pause=10000&color=F7F7F7&center=true&vCenter=true&width=435&lines=JackPts's+Dotfiles)](https://git.io/typing-svg)

- .gitconfig
- TMUX config
- popular terminals config (kitty, alacritty, ghostty)
- neovim config (based on LazyVim)
- fish config (+ a bit of zsh customization)
- sway/quickshell config
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

### Install `Sway` packages

```bash
    sudo pacman -S --needed sway swayidle swaylock swaybg swayimg rofi swaync obs-studio jq wl-clipboard wl-mirror cliphist copyq figlet gum xdg-desktop-portal xdg-desktop-portal-wlr polkit-gnome brightnessctl playerctl grim slurp wf-recorder mpvpaper
    paru -S --needed quickshell arch-update scrot xclip swayshot brightnessctl swww waypaper songrec
```

### Install related packages

```bash
    sudo pacman -S ttf-font-awesome ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-droid ttf-jetbrains-mono ttf-jetbrains-mono-nerd gnome-calendar mpd ncmpcpp networkmanager-dmenu brightnessctl ttf-firacode-nerd kdeconnect fastfetch neofetch curl nushell starship tmux cmatrix cowfortune power-profiles-daemon mpv sass dysk
    paru -S ttf-cascadia-code-nerd mission-center resources checkupdates-with-aur warp-terminal-bin rxfetch ttf-material-design-icons ttf-maple-beta chafa wf-recorder python-pywal
```

### Quickshell (jackbar)

Status bar lives in `.config/quickshell/jackbar` (Sway starts it with `quickshell -p …/jackbar`). Full module/click/package reference: [`quickshell.md`](quickshell.md).

**AI billing** (robot icon): hover shows remaining credits, Daily/Weekly/Monthly spent, Cursor on-demand and days until auto-pay. Copy `modules/billing/secrets.env.example` → `secrets.env` (gitignored). Full tooltip example: [`quickshell.md`](quickshell.md#ai-billing).

| Provider | What to set | Extra session |
|---|---|---|
| OpenRouter | `OPENROUTER_API_KEY` (`sk-or-v1-…`). Optional `OPENROUTER_MGMT_KEY` for token totals | — |
| OpenCode | `OPENCODE_CONSOLE_KEY` (`oc_sk_…`, **All** permissions) + `ZEN_API_KEY` (`sk-…`) | Wallet $ uses Zen/Firefox cookie `__Host-console_session` on `opencode.ai` (or `OPENCODE_CONSOLE_SESSION`) |
| Cursor | none if Cursor IDE is signed in (`state.vscdb`); optional `CURSOR_API_KEY` | if IDE is closed: Zen/Firefox cookie `WorkosCursorSessionToken` on `cursor.com`; `N days until next auto-pay`; `(no auto-pay)` if auto-renew is off |

Left click copies the tooltip; right click refreshes. Put your OpenCode workspace id (`wrk_…`) in `modules/billing/providers.json` → `dashboard_url`.

### Sway

Compositor config: `.config/sway/config`. Keybindings, autostart, NVIDIA session, idle, and wallpaper scripts: [`sway.md`](sway.md).

Idle lock via `asciiquarium` is **commented out**; `$mod+l` currently dims the wallpaper. Re-enable `scripts/asciiquarium_lock.sh` if you want the aquarium overlay (`sudo pacman -S asciiquarium`).

<br />

### Install dotfiles using `Stow` & implement configs

```bash
    sudo pacman -S stow
    git clone --depth 1 https://github.com/jackpts/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow .
```

If error occured with conflicting configs (sway, fish, etc.), then stow like this:

```bash
    stow . --adopt
    git stash
```

### Remove all `Stow` configuration symlinks

```bash
    stow -D .
```

### Change screen resolution & refresh rate in `$HOME/dotfiles/.config/sway/config` to your own:

```conf
output eDP-1 mode 2560x1600@165Hz position 0,0
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


### TODO

- dropdown menus like in mechabar ( <https://github.com/sejjy/mechabar?tab=readme-ov-file> ) for WiFi, BT, Power
