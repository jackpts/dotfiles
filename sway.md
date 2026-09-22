# Sway

i3-compatible Wayland compositor for this tree. Config: [`.config/sway/config`](.config/sway/config). Status bar is jackbar — see [`quickshell.md`](quickshell.md).

`$mod` is **Super** (`Mod4`). Home-row vim keys: `$left/$down/$up/$right` = `h/j/k/l`. Default terminal `$term` is **kitty**. Apps: file manager `nemo`, notes `obsidian`, browser `firefox`. Script prefix `$scripts` is `$HOME/scripts` (same files as `~/dotfiles/scripts` after stow).

---

## Login / NVIDIA

Display managers (SDDM) do **not** source fish `conf.d`, so sessions go through:

| File | Role |
|---|---|
| `.local/share/wayland-sessions/sway.desktop` | Session “Sway” |
| `.local/share/wayland-sessions/sway-nvidia.desktop` | Session “Sway (NVIDIA)” |
| `.config/sway/startup.sh` | Loads env, `exec sway --unsupported-gpu` (wraps `dbus-run-session` if needed) |
| `.config/sway/env` | wlroots/NVIDIA: `WLR_DRM_DEVICES`, `WLR_NO_HARDWARE_CURSORS`, `GBM_BACKEND=nvidia-drm`, `SWAY_UNSUPPORTED_GPU=1`, … |

Edit `.config/sway/env` for your GPU (`/dev/dri/card0` vs `card1`). On a machine without NVIDIA you can still use `startup.sh`; drop `--unsupported-gpu` if Sway complains.

SDDM / Plymouth theming: `scripts/sddm_setup_theme.sh`, `scripts/plymouth_setup_theme.sh`.

---

## Packages

Matches the install block in [`README.md`](README.md), plus a few tools the config actually execs.

### Required

```bash
sudo pacman -S --needed sway swayidle swaylock swaybg jq wl-clipboard wl-mirror \
  grim slurp brightnessctl playerctl pipewire-pulse \
  xdg-desktop-portal xdg-desktop-portal-wlr polkit-gnome \
  networkmanager noto-fonts ttf-jetbrains-mono-nerd
```

### As configured (apps + helpers)

```bash
sudo pacman -S --needed kitty ghostty nemo firefox obsidian nvim \
  rofi swaync copyq cliphist kdeconnect mpv fzf chafa wofi \
  cmatrix gnome-keyring
paru -S --needed quickshell zen-browser-bin wl-color-picker
```

Optional: `asciiquarium` (screensaver script), `voxtype-bin wtype` (push-to-talk), `waypaper` / `swww` (unused; wallpaper is `swaymsg output * bg`), `obs-studio` (`$mod+F10`).

Set your panel output in Sway if needed:

```conf
output eDP-1 mode 2560x1600@165Hz position 0,0
```

(`swaymsg -t get_outputs`)

---

## Keybindings

### Apps / session

| Binding | Action |
|---|---|
| `$mod+Return` | kitty |
| `$mod+x` | kitty (again) |
| `$mod+t` | ghostty |
| `$mod+d` | App launcher (`scripts/run_launcher.sh` → rofi drun) |
| `$mod+e` | nemo |
| `$mod+z` | zen-browser |
| `$mod+n` | Toggle nvim scratchpad (`scripts/toggle_neovim.sh`) |
| `$mod+s` / `$mod+ы` | Toggle Obsidian scratchpad (`bindcode 39` → `toggle_obsidian.sh`) |
| `$mod+w` | Wallpaper picker in kitty (`scripts/wallpaper.sh`) |
| `$mod+r` | Radio menu (`scripts/radio.sh` + mpv) |
| `$mod+F10` | OBS |
| `$mod+c` | Toggle SwayNC |
| `$mod+q` | Kill focused window |
| `$mod+Shift+q` | Power menu (`scripts/powermenu.sh`) |
| `$mod+Shift+e` | Confirm and exit Sway (`swaynag`) |
| `$mod+Shift+c` / `$mod+Shift+r` | Reload Sway config |
| `$mod+l` | Dim wallpaper (`output * bg black opacity 0.5`) |
| `$mod+m` | Mirror eDP-1 → HDMI-A-1 (`wl-mirror`) |
| `$mod+Shift+m` | Stop mirror |
| `$mod+v` hold/release | Voxtype record start/stop |
| `$mod+Shift+p` | Color picker (`wl-color-picker clipboard`) |
| Print | Region screenshot (`slurp` + `grim` → `~/Pictures/Screenshots`) |
| `$mod+Print` | Full screenshot |

### Windows / layout

| Binding | Action |
|---|---|
| `$mod+h/j/k` or arrows | Focus |
| `$mod+Shift+h/j/k/l` or arrows | Move window |
| `$mod+Tab` | Focus next |
| `Alt+Tab` | Toggle tiling/floating focus |
| `$mod+f` | Fullscreen |
| `$mod+Ctrl+f` | Global fullscreen toggle |
| `$mod+Shift+f` / `$mod+Shift+space` | Floating toggle |
| `$mod+space` | Focus tiling ↔ floating |
| `$mod+a` | Focus parent |
| `$mod+Ctrl+h/l/k/j` | Resize ±25px |
| `$mod` + drag LMB | Move floating |
| `$mod` + drag RMB | Resize |

Resize **mode** exists in config (`mode "resize"`) but is **not** bound (`# bindsym $mod+r mode "resize"` — `$mod+r` is radio).

### Workspaces

| Binding | Action |
|---|---|
| `$mod+1` … `$mod+0` | Workspace 1–10 |
| `$mod+Shift+1` … `$mod+0` | Move container there |
| `$mod+Ctrl+Alt+Left/Right` | Move container to prev/next workspace |
| `$mod` + scroll on window | Prev/next workspace on this output |
| 3-finger swipe L/R | Next/prev workspace on this output |

### Hardware keys

| Key | Action |
|---|---|
| XF86 audio raise/lower/mute | `wpctl` sink |
| XF86 mic mute | `wpctl` source |
| XF86 brightness ± | `brightnessctl s 10%±` |
| XF86 play/pause/next/prev | `playerctl --player=playerctld` |

Keyboard layouts: `us,ru` with `grp:alt_shift_toggle` (Alt+Shift). Numlock on.

---

## Window rules

Almost **everything floats** (`for_window [app_id=".*"] floating enable` and the Xwayland `class` equivalent). Warp tiling overrides are commented out.

| Rule | Apps |
|---|---|
| Opacity 0.95 | default |
| 0.98 | zen, Opera |
| 1.0 (opaque) | Chrome, eog, DBeaver |
| Size 60%×50%, | mpv |
| Size 60%×60%, centered | window title `wallpaper` |
| No border, sticky | slurp |

Borders: 2px; focused `#4c789988`.

---

## Autostart

From `config` (order matters for workspace 2):

1. `XDG_*` + `dbus-update-activation-environment --systemd --all`
2. `polkit-gnome-authentication-agent-1`
3. **jackbar:** `quickshell -p $HOME/dotfiles/.config/quickshell/jackbar`
4. After 3s: workspace 2 + **ghostty**
5. `wl-paste --watch cliphist store` (text + image)
6. `copyq`
7. `journalctl --user -u sway` (`exec_always`)
8. `kdeconnect-indicator` after 5s
9. Wallpaper restore: `scripts/wallpaper_save.sh --restore`
10. `xdg-desktop-portal-wlr`

Commented (re-enable as needed): delayed Deluge / Nemo / Telegram, tmux `yt-tg-chat-bot` + daily `sway-backup.sh`, gnome-keyring daemon.

Idle: `swayidle` after 300s runs `output * bg black opacity 0.5`. The older `asciiquarium_lock.sh` + DPMS timeouts are commented.

---

## Config files

| Path | Purpose |
|---|---|
| `.config/sway/config` | Binds, rules, exec |
| `.config/sway/env` | GPU/wlroots (sourced by `startup.sh`) |
| `.config/sway/startup.sh` | Session entry |
| `.config/sway/wallpaper.conf` | Last wallpaper path (`wallpaper="…"`) |
| `.config/sway/wallpaper_last` | Last picker selection |
| `.config/rofi/*.rasi` | Launcher + powermenu themes |
| `.config/wofi/menu.css` | Radio picker (Wayland) |
| `.config/swaync/` | Notification daemon |

---

## Scripts under the hood

Bound or exec’d by Sway (jackbar-only scripts live in [`quickshell.md`](quickshell.md)):

| Script | Binding / when | What |
|---|---|---|
| `startup.sh` | SDDM session | NVIDIA flags + `sway --unsupported-gpu` |
| `run_launcher.sh` | `$mod+d` | rofi `-show drun` (Catppuccin, fallback `style.rasi`) |
| `powermenu.sh` | `$mod+Shift+q` | rofi: lock / suspend / logout / reboot / poweroff |
| `lock_with_matrix.sh` | powermenu lock | fullscreen `cmatrix` in kitty, then `swaylock` |
| `toggle_neovim.sh` | `$mod+n` | kitty `--class nvim` or scratchpad show/hide |
| `toggle_obsidian.sh` | `$mod+s` | launch / scratchpad Obsidian |
| `wallpaper.sh` | `$mod+w` | fzf + chafa thumbs from `~/Pictures/walls` |
| `set_wallpaper.sh` | from picker | `swaymsg output * bg … fill\|fit` |
| `wallpaper_save.sh` | picker + autostart | save/restore `wallpaper.conf` |
| `radio.sh` | `$mod+r` | wofi station list → `mpv --title=radio-mpv` |
| `asciiquarium_lock.sh` | commented `$mod+l` / idle | kitty + `asciiquarium`; any key dismisses |
| `sway-backup.sh` | commented autostart | encrypted 7z (see script; do not commit passwords) |

Picker keys inside wallpaper kitty: Enter set+quit, Ctrl-O fill, Ctrl-R fit, Ctrl-Q quit.

Radio: second `$mod+r` kills the existing `radio-mpv` instance (toggle-off).

---

## Nuances

- **Floating-first:** new windows float; tile with `$mod+Shift+space` if you want i3-like tiling.
- **`$scripts` vs `dotfiles/scripts`:** binds use `$HOME/scripts`. Keep that directory (or symlink) after clone.
- **Obsidian bindcode 39** is physical key `S` (works on US and RU). Do not change to `$mod+s` only — it breaks on the Russian layout.
- **`$mod+r` is radio**, not resize mode.
- **`$mod+l` is not a lock** right now — it only darkens the wallpaper. Real lock is powermenu → lock (`swaylock` + cmatrix).
- **Mouse hang workaround:** device `046D:C077` has `events disabled` (Logitech receiver that was locking input). Remove if you need that device.
- **gnome-keyring** is documented in-config for Zen/editor sign-in; the exec line is commented. Install `gnome-keyring` and uncomment if secrets fail.
- Include drops: `/etc/sway/config-vars.d/*` and `/etc/sway/config.d/*` (distro snippets).

---

## Troubleshooting

- **Black screen / NVIDIA:** pick “Sway (NVIDIA)”, check `WLR_DRM_DEVICES` in `env`, confirm `startup.sh --unsupported-gpu`.
- **No bar:** jackbar path in `exec`; see [`quickshell.md`](quickshell.md).
- **No wallpaper after login:** `wallpaper.conf` path must exist; `wallpaper_save.sh --restore` waits for `swaymsg`.
- **Launcher empty:** rofi + `~/.config/rofi/catppuccin-mocha.rasi`.
- **Radio does nothing:** `wofi` + `mpv`; Wayland session (`XDG_SESSION_TYPE=wayland`).
- **Logs:** `journalctl --user -u sway` (also started from config); SDDM: `journalctl -u sddm -b`.
