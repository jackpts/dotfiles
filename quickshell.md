# Jackbar (Quickshell)

Wayland status bar for this dotfiles tree. QML lives in [`.config/quickshell/jackbar`](.config/quickshell/jackbar); Sway launches it from `.config/sway/config`:

```conf
exec --no-startup-id quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

Layout is defined in `shell.qml`: one `PanelWindow` per output, autohide optional (`settings.conf` → `barAutohide`). Colors/sizes: `components/Theme.qml`.

## Run / reload

```bash
quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"
# or
qs -p "$HOME/dotfiles/.config/quickshell/jackbar"
```

```bash
~/dotfiles/scripts/quickshell_reload.sh
```

Optional env:

| Variable | Effect |
|---|---|
| `QS_PANEL_OUTPUT` | Comma/space list of output names, or `all` / `*` |
| `QS_PANEL_DEBUG` | Log which screens get a panel |

Commented-out modules in `shell.qml` (uncomment to enable): `RedShift`, `HoursNote`, `BlueLight`, `Tray`.

---

## Packages

Arch names. Core is enough for the bar to start; extras unlock individual widgets.

### Required

```bash
# bar + shell helpers
paru -S --needed quickshell
sudo pacman -S --needed bash jq curl python python-requests sqlite wl-clipboard libnotify \
  brightnessctl playerctl grim slurp pavucontrol pipewire-pulse networkmanager \
  bluez bluez-utils ttf-jetbrains-mono-nerd ttf-font-awesome
```

`python-requests` is for `scripts/weather.py` (stdlib `zoneinfo` is enough otherwise). Billing plugins use **stdlib only** (`json`, `csv`, `sqlite3`, `datetime`).

### Strongly recommended (widgets as shipped)

```bash
sudo pacman -S --needed \
  kitty alacritty \
  swaync \
  copyq \
  gnome-calendar \
  blueman \
  htop \
  dysk \
  power-profiles-daemon \
  wf-recorder \
  nemo \
  gsettings-desktop-schemas
paru -S --needed songrec mission-center resources
```

### Optional

```bash
paru -S --needed voxtype-bin wtype voxtype-tui   # Whisper in Settings
sudo pacman -S redshift gammastep                 # night light (commented out in shell.qml)
sudo pacman -S btop                               # MemoryGauge right-click fallback
```

Fonts: a Nerd Font is assumed for icons (`󰚩`, `󰹑`, …). JetBrains Mono Nerd is what Theme uses for monospace tooltips.

---

## Layout (left → right)

**Left:** App menu · updates · weather · task list  
**Center:** Sway/Niri workspaces  
**Right:** music · Shazam · CPU · RAM · disk · volume · settings · network · Bluetooth · **AI billing** · keyboard · recorder · screenshot · clipboard · notifications · battery · clock

---

## Modules and mouse

Hover always shows a tooltip unless noted. Scroll is mouse wheel.

| Module | Left | Right | Other |
|---|---|---|---|
| **AppMenu** | App launcher | Power menu (lock / suspend / logout / reboot / shutdown) | Middle: `swaymsg reload` |
| **UpdatesIndicator** | `kitty` → `pacman -Syu` + `paru -Sua` | — | Hover: package list (`scripts/garuda_updates.sh`) |
| **Weather** | `wttr.in` in Alacritty | Location picker | `python3 ~/scripts/weather.py`; cities in `jackbar/weather-locations.json` |
| **TaskList** | Focus window (`swaymsg`) | Context menu | Sway only for clicks |
| **Workspaces** | Click a workspace | — | Wheel: prev/next |
| **MusicPlayer** | Play/pause | Stop | Wheel: prev/next (`playerctl`) |
| **Shazam** | Toggle listen (`scripts/quickshell_shazam.sh` / `songrec`) | — | |
| **CpuGauge** | `kitty -e htop` | — | `scripts/cpu_with_temp.sh` |
| **MemoryGauge** | `missioncenter` (fallback `gnome-system-monitor`) | `resources` (fallback `btop`) | `scripts/ram_usage_mb.sh` |
| **FreeSpaceGauge** | `kitty` + `dysk` | — | |
| **VolumeGauge** | `pavucontrol` | Mute default sink (`wpctl`) | Wheel: volume; `scripts/volume_apps.sh` |
| **SettingsIndicator** | Open settings panel | — | See Settings below |
| **NetworkIndicator** | Wi-Fi / Ethernet panel | `kitty -e nmtui` | `network-detect.sh`, `vpn-detect.sh`, `geo-lookup.sh` |
| **BluetoothIndicator** | `blueman-manager` | — | `bluetoothctl` |
| **BillingIndicator** | Copy tooltip (`wl-copy`) | Reload stats | See [AI billing](#ai-billing) |
| **LanguageSwitcher** | Next XKB layout | Same | `swaymsg input type:keyboard xkb_switch_layout next` |
| **ScreenRecorder** | Toggle record | Open `~/Videos/Screenrecorder` | `scripts/quickshell_screen_record.sh` |
| **ScreenshotCapture** | Region shot (`slurp` + `grim`) → file + clipboard | Open Screenshots folder | |
| **Clipboard** | Toggle CopyQ | — | Starts `copyq` if needed |
| **NotificationIndicator** | Toggle SwayNC | Dismiss (`swaync-client -d`) | |
| **BatteryGauge** | Power-profile menu | — | `modules/power-profile.sh` |
| **Clock** | `gnome-calendar` | — | Hover calendar; wheel changes month |

---

## Settings panel

Gear icon. Backend: `modules/settings-panel.sh`. Prefs: `settings.conf` next to the shell (`barAutohide`, `fontSize`, `outputScale`).

| Control | What it does |
|---|---|
| Brightness | `brightnessctl` |
| Text size | GTK `gsettings` + Sway title-bar font |
| Output scale | `swaymsg output * scale` |
| Autohide | Collapses the bar to a 3px strip until hover |
| Wallpaper | `scripts/wallpaper.sh` (same as Sway `Mod+w`) |
| Theme | pywal via `scripts/update_term_theme.sh` |
| Color picker | `wl-color-picker clipboard` (`Mod+Shift+p`) |
| Reminders | text + delay → `notify-send` / SwayNC |
| Voxtype | daemon toggle, record, TUI |

Favorites / recent apps: `favorites.conf`, `recent.conf`.

---

## AI billing

Robot icon (`󰚩`). Polls every `poll_seconds` (default 300) via `modules/billing/billing-status.sh`. Tooltip: remaining, Daily/Weekly/Monthly spent, DiskUsage-style bars, Cursor days-until-renew.

Example hover:

```
1. OpenCode — $9.97 left
Daily  $0.00
Weekly  $0.00
Monthly  5.38M tok, $0.00

2. OpenRouter — $14.69 left
Daily  $0.00
Weekly  $0.00
Monthly  $0.41

3. Cursor — $0.00 included left
Daily  2.19M tok (~8.4 MB), $6.39
Weekly  6.20M tok, $20.66
Monthly  15.98M tok, $57.87
On-demand  $55.20
7 days until next auto-pay
_________
Left click: copy tooltip
Right click: refresh
```

### Files

| Path | Role |
|---|---|
| `modules/billing/providers.json` | Enable providers, dashboard URLs, optional USD caps, warn/crit % |
| `modules/billing/secrets.env.example` | Template — **copy** to `secrets.env` |
| `modules/billing/secrets.env` | Secrets (**gitignored**) |
| `modules/billing/plugins/*.sh` | One plugin per provider (`openrouter`, `opencode`, `cursor`) |
| `$HOME/scripts/.env` | Fallback for any key not set in `secrets.env` |

`providers.json` `dashboard_url` for OpenCode must contain your workspace id (`wrk_…`) from [console billing](https://opencode.ai/console) — used as `x-org-id`. Disabled stubs: Warp, Zed, Freebuf (`plugin: "todo"`).

### Fresh-machine setup

```bash
cp ~/.config/quickshell/jackbar/modules/billing/secrets.env.example \
   ~/.config/quickshell/jackbar/modules/billing/secrets.env
chmod 600 ~/.config/quickshell/jackbar/modules/billing/secrets.env
```

Fill keys below. Right-click the robot to poll immediately.

### OpenRouter

1. Create a regular key: https://openrouter.ai/settings/keys (`sk-or-v1-…`).
2. Set `OPENROUTER_API_KEY`. That key is enough for wallet remaining **and** spend (`GET /api/v1/credits`, `GET /api/v1/key`). Tooltip shows UTC day / week (Mon–Sun) / month spend (`usage_daily` / `usage_weekly` / `usage_monthly`).
3. Optional `OPENROUTER_MGMT_KEY` (Management API keys on the same page) for `/activity` token totals on **completed UTC days**. Without it, tokens often show `-`.

No cookies.

### OpenCode

API keys **do not** return the prepaid wallet dollar amount. The widget combines three sources:

| Name | Value | Used for |
|---|---|---|
| `OPENCODE_CONSOLE_KEY` | Console service account `oc_sk_…` created with **All** (usage + budgets), not inference-only | CSV usage export, member budgets. Inference-only → HTTP 403 |
| `ZEN_API_KEY` | Zen inference `sk-…` (alias `OPENCODE_API_KEY`) | `/zen/v1/models`; today’s local spend from `~/.local/share/opencode/opencode.db` |
| Cookie `__Host-console_session` | Host `opencode.ai` | `GET /console/api/billing/status` → prepaid **$ left** |

Cookie is read automatically from Zen Browser / Firefox / LibreWolf `cookies.sqlite` (same idea as Cursor’s local IDE session). Log into https://opencode.ai/console in that browser at least once.

Override if you use another browser:

```bash
# secrets.env — paste the cookie value only, not the name
OPENCODE_CONSOLE_SESSION=
```

Docs: [usage export](https://opencode.ai/console/guides/usage), [budgets](https://opencode.ai/console/guides/budgets). Member budget leftover is only shown when a monthly cap is set; otherwise remaining is the wallet from `/api/billing/status`.

### Cursor

No key if this machine is signed into the Cursor IDE. Plugin reads:

`~/.config/Cursor/User/globalStorage/state.vscdb` → `cursorAuth/accessToken`

Then:

- `GetCurrentPeriodUsage` — included vs on-demand spend, `billingCycleEnd`
- `GetAggregatedUsageEvents` — local calendar Daily / Weekly (Mon–Sun) / Monthly spend
- `GET /auth/full_stripe_profile` — `pendingCancellationDate` / `subscriptionStatus`

If that Bearer token is missing or returns 401/403 (Cursor closed), the plugin falls back to the signed-in Zen / Firefox / LibreWolf cookie `WorkosCursorSessionToken` on `cursor.com` and the same dashboard routes (`POST /api/dashboard/get-current-period-usage`, aggregated events, `GET /api/auth/stripe`). Log into https://cursor.com/dashboard in that browser at least once.

Optional `CURSOR_API_KEY` overrides the local Bearer token. Optional `CURSOR_SESSION_COOKIE` overrides the browser cookie value. A Cursor Admin API key is not required.

Tooltip extra line (last in the Cursor block): `8 days until next auto-pay`; `8 days until cycle ends (no auto-pay)` if auto-renew is off (cancel-at-period-end). Included `$20 / $20` bar is omitted once the included allowance is exhausted — the header already shows `$0.00 included left`; On-demand is the extra spend. The included bar returns at the start of a cycle while some of the $20 remains.

### Behaviour / caveats

- Icon color: ok / warn / crit from remaining and limit percents (`warn_percent` / `critical_percent` in `providers.json`).
- Today’s “size” is `tokens × 4` bytes (estimate). APIs do not report real network MB.
- Add a provider later: object in `providers.json` + executable `plugins/<id>.sh` emitting the JSON contract in `billing-status.sh`.

---

## Config files in jackbar

| File | Purpose |
|---|---|
| `shell.qml` | Module order, per-output panel |
| `settings.conf` | Autohide, font size, output scale |
| `weather-locations.json` | Weather city list (`id`, `name`, `lat`, `lon`) |
| `favorites.conf` / `recent.conf` | App menu |
| `components/Theme.qml` | Colors, panel height, fonts |
| `modules/billing/providers.json` | Billing providers |

---

## Scripts used by the bar

From `~/dotfiles/scripts/` (or `$HOME/scripts` when that is the same tree after stow):

| Script | Who calls it |
|---|---|
| `weather.py` | Weather |
| `cpu_with_temp.sh` | CPU |
| `ram_usage_mb.sh` | Memory |
| `volume_apps.sh` | Volume tooltip |
| `garuda_updates.sh` | Updates |
| `quickshell_shazam.sh` | Shazam |
| `quickshell_screen_record.sh` | Recorder |
| `quickshell_reload.sh` | Manual bar restart |
| `wallpaper.sh` | Settings wallpaper |
| `update_term_theme.sh` | Settings theme |
| `lock_with_matrix.sh` | AppMenu lock/suspend |

In-tree helpers:

| Script | Who |
|---|---|
| `modules/billing/billing-status.sh` | Billing |
| `modules/settings-panel.sh` | Settings |
| `modules/network-panel.sh` | Network panel |
| `modules/network-detect.sh` | Network icon |
| `modules/vpn-detect.sh` | VPN badge |
| `modules/geo-lookup.sh` | Public IP → city (cached 7d) |
| `modules/power-profile.sh` | Battery profiles |
| `modules/voxtype-status.sh` | Whisper row in Settings |

---

## Troubleshooting

- **Bar missing on a screen:** `QS_PANEL_OUTPUT`, or the output name starts with `HEADLESS`.
- **Billing spinner forever / parse error:** `jq`, `curl`, `python3`; run `modules/billing/billing-status.sh` in a terminal.
- **OpenCode remaining `-`:** log into Console in Zen/Firefox, or set `OPENCODE_CONSOLE_SESSION`; confirm `dashboard_url` contains `wrk_…`.
- **OpenCode 403:** recreate `oc_sk_…` with **All**, not Inference only.
- **Cursor empty / HTTP 403:** open Cursor IDE once so `state.vscdb` has `cursorAuth/accessToken`, *or* log into https://cursor.com/dashboard in Zen/Firefox so `WorkosCursorSessionToken` is in `cookies.sqlite`.
- **Weather `...`:** `python-requests`; `python3 ~/scripts/weather.py --json`.
- **Reload stuck:** `lsof` the lock under `$XDG_RUNTIME_DIR/quickshell-jackbar.reload.lock` (see `quickshell_reload.sh`).
