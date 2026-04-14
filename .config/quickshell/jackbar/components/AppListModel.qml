import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string filter: ""
    property var allApps: []
    property alias count: listModel.count
    
    // Expose the internal model for use in Repeater/ListView
    readonly property var model: listModel

    signal loaded()

    ListModel {
        id: listModel
    }

    // Use a process to get apps via a shell command
    Process {
        id: loadAppsProc
        command: ["bash", "-c",
            "for dir in \"$HOME/.local/share/applications\" /usr/share/applications /usr/local/share/applications; do " +
            "  [ -d \"$dir\" ] || continue; " +
            "  for f in \"$dir\"/*.desktop; do " +
            "    [ -f \"$f\" ] || continue; " +
            "    awk '/^\\[Desktop Entry\\]/{ok=1} /^\\[/{if($0!=\"[Desktop Entry]\")ok=0} ok && /^Name=/{name=substr($0,6)} ok && /^Exec=/{exec=substr($0,6)} ok && /^Icon=/{icon=substr($0,6)} ok && /^(Hidden|NoDisplay)=true/{skip=1} END{if(!skip && name && exec) print name \"|\" exec \"|\" icon}' \"$f\" 2>/dev/null; " +
            "  done; " +
            "done | sort -u -t'|' -k1"
        ]
        stdout: StdioCollector {
            onStreamFinished: parseApps(this.text)
        }
    }

    Component.onCompleted: loadApps()

    function get(index) {
        return listModel.get(index);
    }

    function append(data) {
        listModel.append(data);
    }

    function clear() {
        listModel.clear();
    }

    function loadApps() {
        clear();
        loadAppsProc.running = true;
    }

    function parseApps(output) {
        if (!output) return;

        var tempApps = [];
        var lines = output.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line) continue;

            var parts = line.split("|");
            if (parts.length >= 2) {
                var name = parts[0];
                var exec = parts[1].replace(/%[fFuUdDnNickvm]/g, "").trim();
                var icon = parts[2] || "";

                var iconChar = getIconForApp(icon, exec, name);

                var app = {
                    name: name,
                    exec: exec,
                    icon: iconChar
                };

                tempApps.push(app);
                append(app);
            }
        }
        // Reassign entire array so QML detects the change
        allApps = tempApps;
        loaded();
    }

    function getIconForApp(iconName, execCmd, appName) {
        var iconMap = {
            "firefox": "󰈹", "firefox-esr": "󰈹", "firedragon": "󰈹",
            "chromium": "󰖟", "google-chrome": "󰊯", "brave": "󰖟",
            "vivaldi": "󰖟", "opera": "󰖟", "librewolf": "󰈹",
            "code": "󰨞", "code-oss": "󰨞", "codium": "󰨞",
            "nvim": "󰕷", "neovim": "󰕷", "vim": "󰕷",
            "emacs": "󰘳", "nano": "󰕷",
            "alacritty": "󰆍", "kitty": "󰆍", "foot": "󰆍",
            "wezterm": "󰆍", "konsole": "󰆍", "gnome-terminal": "󰆍",
            "xfce4-terminal": "󰆍", "st": "󰆍", "terminator": "󰆍",
            "thunar": "󰉋", "nautilus": "󰉋", "dolphin": "󰉋",
            "pcmanfm": "󰉋", "ranger": "󰉋", "nemo": "󰉋",
            "caja": "󰉋", "nnn": "󰉋", "vifm": "󰉋",
            "spotify": "󰓇", "vlc": "󰕼", "mpv": "󰕼",
            "obs": "󰑋", "simplescreenrecorder": "󰑋",
            "discord": "󰙯", "slack": "󰒱", "telegram": "󰕐",
            "telegramdesktop": "󰕐", "thunderbird": "󰇰",
            "evolution": "󰇰", "geary": "󰇰", "mutt": "󰇰",
            "gimp": "󰏘", "inkscape": "󰏘", "krita": "󰏘",
            "blender": "󰂫", "kdenlive": "󰗃",
            "steam": "󰓓", "lutris": "󰓓", "heroic": "󰓓",
            "minecraft": "󰍳", "prismlauncher": "󰍳",
            "multimc": "󰍳", "atlauncher": "󰍳",
            "libreoffice": "󰏆", "libreoffice-writer": "󰈭",
            "libreoffice-calc": "󰈩", "libreoffice-impress": "󰈩",
            "zathura": "󰈦", "okular": "󰈦", "evince": "󰈦",
            "mupdf": "󰈦", "qpdfview": "󰈦",
            "gnome-control-center": "󰒓", "pavucontrol": "󰕾",
            "nm-connection-editor": "󰤨", "blueman-manager": "󰂯",
            "htop": "󰘦", "btop": "󰘦", "top": "󰘦",
            "neofetch": "󰌽", "fastfetch": "󰌽",
            "flameshot": "󰹑", "grim": "󰹑", "shotgun": "󰹑",
            "filezilla": "󰘣", "transmission": "󰌛",
            "qbittorrent": "󰌛", "deluge": "󰌛",
            "gnome-calculator": "󰃬", "kcalc": "󰃬", "galculator": "󰃬"
        };

        // Try to match by icon name
        if (iconName) {
            var key = iconName.toLowerCase();
            if (iconMap[key]) return iconMap[key];
        }

        // Try to match by exec command
        if (execCmd) {
            var execBase = execCmd.split(" ")[0].split("/").pop().toLowerCase();
            if (iconMap[execBase]) return iconMap[execBase];
        }

        // Try to match by app name
        if (appName) {
            var nameKey = appName.toLowerCase().replace(/[^a-z0-9]/g, "");
            if (iconMap[nameKey]) return iconMap[nameKey];
        }

        // Pattern matching for icon names
        if (iconName) {
            var lower = iconName.toLowerCase();
            if (lower.includes("browser") || lower.includes("web")) return "󰖟";
            if (lower.includes("terminal") || lower.includes("term")) return "󰆍";
            if (lower.includes("folder") || lower.includes("file") || lower.includes("dir")) return "󰉋";
            if (lower.includes("text") || lower.includes("edit") || lower.includes("write")) return "󰈭";
            if (lower.includes("media") || lower.includes("video") || lower.includes("movie")) return "󰕼";
            if (lower.includes("music") || lower.includes("audio") || lower.includes("sound")) return "�";
            if (lower.includes("image") || lower.includes("photo") || lower.includes("pic")) return "󰏘";
            if (lower.includes("game") || lower.includes("play") || lower.includes("steam")) return "󰓓";
            if (lower.includes("setting") || lower.includes("config") || lower.includes("pref")) return "󰒓";
            if (lower.includes("network") || lower.includes("wifi") || lower.includes("net")) return "�";
            if (lower.includes("mail") || lower.includes("email")) return "󰇰";
            if (lower.includes("chat") || lower.includes("message")) return "󰭹";
            if (lower.includes("calc") || lower.includes("math")) return "󰃬";
        }

        // Default fallback
        return "󰣆";
    }

    onFilterChanged: {
        clear();
        if (!filter || filter === "") {
            // Restore all apps
            for (var i = 0; i < allApps.length; i++) {
                append(allApps[i]);
            }
        } else {
            // Filter apps by name or exec
            var searchLower = filter.toLowerCase();
            for (var j = 0; j < allApps.length; j++) {
                var app = allApps[j];
                if (app.name.toLowerCase().indexOf(searchLower) !== -1 ||
                    app.exec.toLowerCase().indexOf(searchLower) !== -1) {
                    append(app);
                }
            }
        }
    }
}
