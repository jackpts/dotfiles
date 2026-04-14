import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string favoritesFile: Quickshell.env("HOME") + "/.config/quickshell/jackbar/favorites.conf"
    property alias count: listModel.count
    
    // Expose the internal model for use in Repeater/ListView
    readonly property var model: listModel

    signal loaded()

    ListModel {
        id: listModel
    }

    Component.onCompleted: {
        ensureDir.running = true;
    }

    Process {
        id: ensureDir
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.config/quickshell/jackbar"]
        onExited: loadFavorites()
    }

    Process {
        id: readFileProc
        stdout: StdioCollector {
            onStreamFinished: {
                parseContent(this.text);
            }
        }
    }

    Process {
        id: writeFileProc
    }

    function get(index) {
        return listModel.get(index);
    }

    function append(data) {
        listModel.append(data);
    }

    function insert(index, data) {
        listModel.insert(index, data);
    }

    function remove(index) {
        listModel.remove(index);
    }

    function clear() {
        listModel.clear();
    }

    function loadFavorites() {
        clear();
        readFileProc.command = ["cat", favoritesFile];
        readFileProc.running = true;
    }

    function parseContent(content) {
        if (!content || content === "") {
            addDefaultFavorites();
            loaded();
            return;
        }

        var lines = content.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "" || line.startsWith("#")) continue;

            var parts = line.split("|");
            if (parts.length >= 2) {
                var name = parts[0];
                var exec = parts[1];
                var icon = parts[2] || "󰣆";

                append({
                    name: name,
                    exec: exec,
                    icon: icon
                });
            }
        }
        loaded();
    }

    function saveFavorites() {
        var content = "# QuickShell Favorites\n";
        content += "# Format: name|exec|icon\n\n";

        for (var i = 0; i < count; i++) {
            var item = get(i);
            content += item.name + "|" + item.exec + "|" + item.icon + "\n";
        }

        writeFileProc.command = ["bash", "-c", "echo '" + escapeShell(content) + "' > " + favoritesFile];
        writeFileProc.running = true;
    }

    function escapeShell(str) {
        return str.replace(/'/g, "'\"'\"'");
    }

    function addFavorite(name, exec, icon) {
        for (var i = 0; i < count; i++) {
            var item = get(i);
            if (item.exec === exec) return;
        }

        append({
            name: name,
            exec: exec,
            icon: icon || "󰣆"
        });

        saveFavorites();
    }

    function removeFavorite(exec) {
        for (var i = 0; i < count; i++) {
            var item = get(i);
            if (item.exec === exec) {
                remove(i);
                saveFavorites();
                return;
            }
        }
    }

    function addDefaultFavorites() {
        var defaults = [
            { name: "Firefox", exec: "firefox", icon: "󰈹" },
            { name: "Terminal", exec: "alacritty", icon: "󰆍" },
            { name: "Files", exec: "thunar", icon: "󰉋" },
            { name: "Editor", exec: "code", icon: "󰨞" }
        ];

        for (var i = 0; i < defaults.length; i++) {
            append(defaults[i]);
        }

        saveFavorites();
    }

    function isFavorite(exec) {
        for (var i = 0; i < count; i++) {
            if (get(i).exec === exec) return true;
        }
        return false;
    }
}
