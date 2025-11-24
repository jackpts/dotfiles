# Jackbar (Quickshell)

- Location: `~/dotfiles/.config/quickshell/jackbar`
- Purpose: Quickshell port of your Waybar modules with graphical circle gauges.

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

- Sway: add another exec (keep Waybar line):

```conf
exec --no-startup-id quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

- Niri: add in `binds` section or startup:

```kdl
spawn-sh-at-startup "quickshell -p $HOME/dotfiles/.config/quickshell/jackbar"
```

## Modules

- **CPU, Memory, Free space, Volume, Battery** - Circular gauges (hover shows value; click/scroll actions preserved where applicable).
- **Network indicator** - Click: `networkmanager_dmenu`, Right-click: `nmtui`.
- **Screenshot button** - Click to capture (slurp + grim -> file + clipboard).
- **Screen recorder** - Uses your `scripts/screen_record.sh` with toggle and status polling.
- **Updates indicator** - Uses your `scripts/garuda_updates.sh`.
- **MusicPlayer** - MPRIS media player control via `playerctl`:
  - Displays current track (artist - title) with play/pause/stop icon
  - Left click: Play/Pause
  - Right click: Stop
  - Scroll up: Previous track
  - Scroll down: Next track
  - Hover: Shows full metadata tooltip
  - Auto-updates every 2 seconds
  - Works with any MPRIS-compatible player (Spotify, VLC, Firefox, Chrome, etc.)

## Notes

- You can fine-tune colors and sizes in `components/CircleGauge.qml` and module files.
- Tray, language, and taskbar are not included in this first pass; can be added later using Quickshell services.
