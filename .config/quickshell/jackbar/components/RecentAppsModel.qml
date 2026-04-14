import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string recentFile: Quickshell.env("HOME") + "/.config/quickshell/jackbar/recent.conf"
    property int maxItems: 16
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
        onExited: loadRecent()
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

    function loadRecent() {
        clear();
        readFileProc.command = ["cat", recentFile];
        readFileProc.running = true;
    }

    function parseContent(content) {
        if (!content || content === "") {
            loaded();
            return;
        }

        var seenNames = {};
        var lines = content.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "" || line.startsWith("#")) continue;

            var parts = line.split("|");
            if (parts.length >= 2) {
                var name = parts[0];
                var exec = parts[1];
                var icon = parts[2] || "󰣆";

                // Skip duplicates by name
                if (seenNames[name]) continue;
                seenNames[name] = true;

                append({
                    name: name,
                    exec: exec,
                    icon: icon
                });
            }
        }
        loaded();
    }

    function saveRecent() {
        var content = "# QuickShell Recent Applications\n";
        content += "# Format: name|exec|icon\n\n";

        for (var i = 0; i < count; i++) {
            var item = get(i);
            content += item.name + "|" + item.exec + "|" + item.icon + "\n";
        }

        writeFileProc.command = ["bash", "-c", "echo '" + escapeShell(content) + "' > " + recentFile];
        writeFileProc.running = true;
    }

    function escapeShell(str) {
        return str.replace(/'/g, "'\"'\"'");
    }

    function addRecent(name, exec, icon) {
        // Remove duplicates by name OR exec (to move to top and avoid dupes)
        for (var i = count - 1; i >= 0; i--) {
            var item = get(i);
            if (item.exec === exec || item.name === name) {
                remove(i);
            }
        }

        // Insert at beginning
        insert(0, {
            name: name,
            exec: exec,
            icon: icon || "󰣆"
        });

        // Trim to max items
        while (count > maxItems) {
            remove(count - 1);
        }

        saveRecent();
    }

    function clearRecent() {
        clear();
        saveRecent();
    }
}
