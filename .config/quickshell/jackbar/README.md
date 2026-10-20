# Jackbar (Quickshell)

- Location: `~/dotfiles/.config/quickshell/jackbar`
- Full docs (modules, clicks, packages, billing keys/cookies): [`../../../quickshell.md`](../../../quickshell.md)

## Run

```bash
quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
# or
qs -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

Sway already starts it:

```conf
exec --no-startup-id quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

Reload: `~/dotfiles/scripts/quickshell_reload.sh`

Optional XDG name:

```bash
mkdir -p ~/.config/quickshell
ln -s "$HOME/dotfiles/.config/quickshell/jackbar" ~/.config/quickshell/jackbar
quickshell -c jackbar
```

## Voxtype / Whisper (optional)

Controls live in the **Settings** panel.

```bash
paru -S voxtype-bin wtype
# optional
paru -S voxtype-tui
voxtype setup model
voxtype setup systemd
systemctl --user enable --now voxtype
```

Push-to-talk: hold `Super+v` (Sway).
