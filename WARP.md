# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

Personal dotfiles for Arch Linux (Garuda Linux) with Hyprland window manager, including configurations for terminals (Kitty, Alacritty, Ghostty, Warp), Neovim (LazyVim-based), Fish shell, Waybar, and various system utilities.

## Core Commands

### Deployment

**Install dotfiles using Stow:**
```bash
stow .
```

**If conflicts occur (files already exist):**
```bash
stow . --adopt    # Adopts existing files into the stow structure
git stash         # Stashes adopted changes to restore originals
```

**Remove all Stow symlinks:**
```bash
stow -D .
```

### System Updates

```bash
# Update system packages
sudo pacman -Suyy

# Update AUR packages (using paru)
paru -Suyy --noconfirm
```

### Hyprland & Waybar

**Reload Hyprland configuration:**
```bash
hyprctl reload
```

**Restart Waybar:**
```bash
pkill waybar && waybar
```

**Kill Waybar (SIGUSR2 signal):**
```bash
killall -SIGUSR2 waybar
```

**Start Waybar with debug logging:**
```bash
WAYBAR_LOG_LEVEL=trace waybar
```

**Compile Waybar SCSS to CSS:**
```bash
cd ~/.config/waybar
sass style.scss style.css
# Remove the first line: @charset "UTF-8";
sed '/@charset "UTF-8";/d' style.css > /tmp/style.css && mv /tmp/style.css style.css
```

Or use Fish function: `w_styles`

### Neovim (LazyVim-based)

**Open Neovim:**
```bash
nvim
```

**Key configurations:**
- Shell set to Fish: `/usr/bin/fish`
- Tab width: 4 spaces
- Clipboard: System clipboard (`unnamedplus`)
- No swapfiles, no relative numbers, no autoformat by default

**Important keymaps:**
- `<leader><leader>` - Find files (with hidden)
- `<leader>/` - Live grep with args
- `<leader>e` - Toggle Neo-tree
- `<leader>gn` - Open Neogit
- `,c` + number - Quick colorscheme switching
- `H` / `L` - Jump to start/end of line
- `jj` in insert mode - Exit to normal mode
- `qq` in normal mode - Quit

**LazyVim extras enabled:**
- TypeScript, JSON, Git, SQL, YAML, Docker
- ESLint, Prettier, none-ls
- Debugging (DAP) and testing

### Fish Shell

**Configuration structure:**
Fish config is split into modular files under `.config/fish/conf.d/`:
- `00-env.fish` - Environment variables, PATH, locales
- `10-aliases_abbr.fish` - Aliases and abbreviations
- `20-functions.fish` - User functions
- `30-integrations.fish` - Tool integrations (fzf, zoxide, etc.)
- `99-interactive.fish` - Greeting, keybindings, interactive UX

**Important Fish functions:**
- `w_toggle` - Toggle Waybar on/off
- `w_styles` - Compile Waybar SCSS to CSS (with charset cleanup)
- `ex <file>` - Universal archive extractor
- `gcl <url>` - Git clone and cd into directory
- `gcld <url>` - Shallow git clone (depth 1) and cd
- `mkcd <dir>` - Create directory and cd into it
- `mp4_to_gif <file>` - Convert MP4 to optimized GIF

**Key Fish abbreviations:**
- `dot` - cd to `$HOME/dotfiles`
- `n` - nvim
- `..` / `...` / `....` - Navigate up directories
- `h_edit` - Edit Hyprland config
- `h_reload` - Reload Hyprland
- `w_kill` / `w_start` - Kill/start Waybar
- `backup` - Run backup script (`sway-backup.sh`)

### Scripts

All utility scripts are in `$HOME/scripts/` (or `$HOME/dotfiles/scripts/`). See `scripts/README.md` for full documentation.

**Key scripts:**
- `run_launcher.sh` - Application launcher (Rofi/Walker with fallbacks)
- `launch_btop.sh` - Launch system monitor with optimal terminal config
- `screen_record.sh` - Screen recording with various options
- `restore_wallpaper.sh` - Restore wallpaper on startup
- `update_term_theme.sh` - Update terminal theme (use `term_theme` abbr)
- `powermenu.sh` - Power menu (shutdown/reboot/logout)
- `garuda_updates.sh` - Check for system updates
- `ram_usage_mb.sh`, `home_free_space.sh`, `system_info.sh` - Waybar monitoring scripts
- `keyboard_layout.sh` - Detect and display keyboard layout

**Run scripts directly:**
```bash
bash $HOME/scripts/script_name.sh
```

### Testing & Validation

**Check Hyprland syntax:**
```bash
hyprctl reload  # Will show errors if config is invalid
```

**Verify Waybar config:**
```bash
waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css
```

**Test Fish config:**
```bash
fish --no-config  # Start clean shell to test
```

## Architecture & Structure

### Configuration Organization

**Hyprland:**
Main config: `.config/hypr/hyprland.conf` sources modular files:
- `mocha.conf` - Catppuccin colors
- `envs.conf` - Environment variables
- `rules.conf` - Window rules
- `binds.conf` - Keybindings
- `execs.conf` - Autostart applications
- `settings.conf` - General settings

**Neovim:**
LazyVim-based configuration:
- `lua/config/lazy.lua` - Lazy.nvim setup with LazyVim extras
- `lua/config/options.lua` - Vim options
- `lua/config/keymaps.lua` - Custom keybindings
- `lua/plugins/` - Custom plugin configurations

### Script Integration with Waybar

Scripts output JSON format for Waybar modules:
- Use caching (e.g., `system_info.sh` caches for 30 seconds)
- Error handling with fallbacks
- Tooltips with detailed information
- CSS classes for styling

### Special Workspaces (Hyprland)

Accessible via keybindings (MOD = SUPER):
- `MOD + I` - Toggle special workspace (generic)
- `MOD + SHIFT + E` - File manager (Nemo)
- `CTRL + ESCAPE` - Htop
- `MOD + A` - Audio controls (pavucontrol)
- `MOD + N` - Neovim editor
- `MOD + S` - Obsidian notes

### Terminal Theming

Terminal themes are managed via `pywal`:
```bash
wal -i <wallpaper_path>  # Generate color schemes
term_theme               # Update terminal configs (Fish abbr)
```

Supported terminals: Kitty, Alacritty, Ghostty

## Important Notes

### Monitor Configuration

Edit monitor settings in `.config/hypr/hyprland.conf`:
```conf
monitor = eDP-1, 2560x1600@165, auto, 1
```

Current setting: `2560x1600@60`

### Display Manager Themes

**SDDM theme setup:**
```bash
bash $HOME/scripts/sddm_setup_theme.sh
```

**Plymouth theme setup:**
```bash
bash $HOME/scripts/plymouth_setup_theme.sh
```

### Package Management

- Primary package manager: `pacman`
- AUR helper: `paru`
- Always run updates with `sudo pacman -Suyy` before `paru -Suyy`

### Window Manager Keybindings

Primary modifier: `SUPER` (Windows key)

**Core bindings:**
- `SUPER + T` - Warp Terminal
- `SUPER + X` - Kitty (floating)
- `SUPER + D` - Launcher
- `SUPER + Q` - Kill active window
- `SUPER + SHIFT + Q` - Power menu
- `SUPER + F` - Fullscreen
- `SUPER + W` - Wallpaper picker (waypaper)
- `SUPER + L` - Lock screen
- `PRINT` - Screenshot region
- `SUPER + PRINT` - Screenshot fullscreen

**Window navigation:**
- `SUPER + h/j/k/l` - Move focus (vim-style)
- `SUPER + SHIFT + h/j/k/l` - Move window
- `SUPER + CTRL + h/j/k/l` - Resize window
- `SUPER + 1-9` - Switch workspace
- `SUPER + SHIFT + 1-9` - Move window to workspace (silent)

### Development Workflow

1. Edit dotfiles in `$HOME/dotfiles/`
2. Stow will automatically symlink to home directory
3. Reload affected applications (Hyprland, Waybar, etc.)
4. Test changes before committing
5. Use `git stash` to temporarily remove adopted changes

### Common Issues

**Stow conflicts:**
Remove or backup existing files before running `stow .`, or use `stow . --adopt` to adopt them.

**Waybar not updating:**
Use `pkill waybar && waybar` instead of `killall -SIGUSR2 waybar` for full restart.

**Hyprland config errors:**
Check syntax with `hyprctl reload` - it will output error messages.

**Fish config not loading:**
Check for syntax errors in individual conf.d files. Use `fish --no-config` to start clean.
