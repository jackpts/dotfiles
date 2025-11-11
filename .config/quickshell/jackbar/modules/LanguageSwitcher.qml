import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32; height: 40

    property string textValue: "--"
    property string tooltipText: "Layout: --"

    function shortFromName(name) {
        if (!name || !name.length) return "--"
        const lower = name.toLowerCase()
        if (lower.indexOf("russian") !== -1 || lower.indexOf("ru") !== -1) return "ru"
        if (lower.indexOf("english (us)") !== -1 || lower.indexOf("us") !== -1 || lower.indexOf("english") !== -1) return "us"
        // fallback to first two letters
        return (name.match(/[a-zA-Z]{2}/) || ["--"])[0].toLowerCase()
    }

    Process {
        id: fetch
        // Read active keyboard layout name; fall back to empty if none
        command: ["bash","-lc",
            "swaymsg -t get_inputs -r | jq -r '.[] | select(.type==\"keyboard\") | .xkb_active_layout_name' | sed -n '1p'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var activeName = (text || "").trim()
                if (!activeName.length) activeName = "--"
                root.textValue = root.shortFromName(activeName).toUpperCase()
                root.tooltipText = "Keyboard: " + activeName
            }
        }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: fetch.running = true }

    Process { id: run }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            // Cycle to next layout on any click
            run.command = ["bash","-lc","swaymsg input type:keyboard xkb_switch_layout next"]
            run.running = true
            // Refresh after a short delay to reflect the change
            Qt.callLater(function() { fetch.running = true })
        }
        onEntered: {
            const html = root.tooltipText.replace(/\r?\n/g, '<br/>')
            C.Tooltip.show(root, html)
        }
        onExited: C.Tooltip.hide()
    }

    Text {
        anchors.centerIn: parent
        text: textValue
        color: {
            if (textValue === "RU") return C.Theme.languageRu
            if (textValue === "US") return C.Theme.languageUs
            return C.Theme.text
        }
        font.pixelSize: 14
        enabled: false
    }
}


