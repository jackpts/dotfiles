pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: store

    property bool barAutohide: false
    property int fontSize: 12
    property real outputScale: 1.0
    property bool loaded: false
    property bool _suppressSave: false

    readonly property string confPath: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/settings.conf"
    readonly property string script: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/modules/settings-panel.sh"

    function parseConf(text) {
        var lines = (text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line.length || line.charAt(0) === "#")
                continue
            var eq = line.indexOf("=")
            if (eq < 0)
                continue
            var key = line.substring(0, eq).trim()
            var val = line.substring(eq + 1).trim()
            if (key === "barAutohide")
                store.barAutohide = (val === "true" || val === "1")
            else if (key === "fontSize") {
                var n = parseInt(val)
                if (!isNaN(n) && n >= 10 && n <= 20)
                    store.fontSize = n
            } else if (key === "outputScale") {
                var s = parseFloat(val)
                if (!isNaN(s) && s > 0)
                    store.outputScale = s
            }
        }
    }

    function confText() {
        return "barAutohide=" + (store.barAutohide ? "true" : "false") + "\n"
            + "fontSize=" + store.fontSize + "\n"
            + "outputScale=" + store.outputScale + "\n"
    }

    function save() {
        if (!store.loaded || store._suppressSave)
            return
        saveProc.command = [
            "bash", "-lc",
            "mkdir -p \"$(dirname \"" + store.confPath + "\")\" && cat > \"" + store.confPath + "\" <<'EOF'\n"
                + store.confText() + "EOF"
        ]
        saveProc.running = false
        saveProc.running = true
    }

    function setBarAutohide(on) {
        if (store.barAutohide === on)
            return
        store.barAutohide = !!on
    }

    function setFontSize(px) {
        var n = Math.round(px)
        n = Math.max(10, Math.min(20, n))
        if (store.fontSize === n)
            return
        store.fontSize = n
        save()
        applyFont()
    }

    function setOutputScale(factor) {
        var s = Number(factor)
        if (isNaN(s) || s <= 0)
            return
        if (Math.abs(store.outputScale - s) < 0.001)
            return
        store.outputScale = s
        save()
        applyScale()
    }

    // Update store from live system values without re-applying
    function syncFontSize(px) {
        var n = Math.round(px)
        if (isNaN(n) || n < 10 || n > 20)
            return
        if (store.fontSize === n)
            return
        store._suppressSave = true
        store.fontSize = n
        store._suppressSave = false
        save()
    }

    function syncOutputScale(factor) {
        var s = Number(factor)
        if (isNaN(s) || s <= 0)
            return
        if (Math.abs(store.outputScale - s) < 0.001)
            return
        store._suppressSave = true
        store.outputScale = s
        store._suppressSave = false
        save()
    }

    function applyFont() {
        applyFontProc.command = [store.script, "font", "set", String(store.fontSize)]
        applyFontProc.running = false
        applyFontProc.running = true
    }

    function applyScale() {
        applyScaleProc.command = [store.script, "scale", "set", String(store.outputScale)]
        applyScaleProc.running = false
        applyScaleProc.running = true
    }

    function applyOnStartup() {
        applyFont()
        applyScale()
    }

    Process {
        id: loadProc
        command: ["bash", "-lc", "[ -f \"" + store.confPath + "\" ] && cat \"" + store.confPath + "\" || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                store._suppressSave = true
                store.parseConf(text)
                store._suppressSave = false
                store.loaded = true
                store.applyOnStartup()
            }
        }
    }

    Process { id: saveProc }
    Process { id: applyFontProc }
    Process { id: applyScaleProc }

    Component.onCompleted: {
        loadProc.running = true
    }

    onBarAutohideChanged: {
        if (store.loaded)
            save()
    }
}
