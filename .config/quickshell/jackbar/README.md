# Jackbar (Quickshell)

- Location: `~/dotfiles/.config/quickshell/jackbar`
- Purpose: Quickshell bar with graphical circle gauges and compositor-agnostic design.
- Supports: Hyprland, Sway, Niri (auto-detected)

## Run

- Directly from this folder (keeps it inside dotfiles):

```bash
quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
# or
qs -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

- Optional: symlink into XDG config and run by name:

```bash
mkdir -p ~/.config/quickshell
ln -s "$HOME/dotfiles/.config/quickshell/jackbar" ~/.config/quickshell/jackbar
quickshell -c jackbar
```

## Run alongside Waybar

- Hyprland: add to `~/.config/hypr/execs.conf`:

```conf
exec-once = quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

- Sway: add another exec (keep Waybar line):

```conf
exec --no-startup-id quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

- Niri: add in `binds` section or startup:

```kdl
spawn-sh-at-startup "quickshell -p $HOME/dotfiles/.config/quickshell/jackbar"
```

## Modules

- CPU, Memory, Free space, Volume, Battery as circular gauges (hover shows value; click/scroll actions preserved where applicable).
- Network indicator (click: `networkmanager_dmenu`, right-click: `nmtui`).
- Screenshot button (slurp + grim -> file + clipboard).
- Screen recorder (uses your `scripts/screen_record.sh` with toggle and status polling).
- Updates indicator (uses your `scripts/garuda_updates.sh`).

## Notes

- The bar auto-detects your compositor (Hyprland, Sway, or Niri) and adapts accordingly.
- Workspaces module: Hyprland uses `hyprctl workspaces`, Sway uses `swaymsg`, Niri has a fallback.
- TaskList module: Hyprland uses `hyprctl clients`, Sway uses `swaymsg -t get_tree`.
- Language switcher: Hyprland uses `hyprctl devices` and `switchxkblayout`, Sway uses input commands.
- You can fine-tune colors and sizes in `components/CircleGauge.qml` and `components/Theme.qml`.
