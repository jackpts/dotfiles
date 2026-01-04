import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C
import QtQuick.Window

Item {
    id: root
    width: 70; height: 50
    property string textValue: "0 󰚰"
    property string statusClass: "ok" // "ok" or "updates"
    property string tooltipText: "System is up to date"

    Process {
        id: proc
        command: ["bash","-lc","$HOME/scripts/garuda_updates.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj && obj.pacman !== undefined && obj.aur !== undefined) {
                        root.textValue = "⟳ " + obj.pacman + "+" + obj.aur
                    } else if (obj && obj.text) {
                        root.textValue = obj.text
                    }
                    if (obj && obj.class) root.statusClass = obj.class
                    if (obj && obj.tooltip) root.tooltipText = obj.tooltip
                } catch (e) {}
            }
        }
    }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            run.command = ["bash","-lc","kitty -e bash -lc 'sudo pacman -Syu && paru -Sua --noconfirm; notify-send \"Update complete\"; read -n 1 -s -p \"Press any key to close\"' "]
            run.running = true
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: textValue
        color: statusClass === "updates" ? C.Theme.updatesAvailable : C.Theme.updatesNone
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }

    // Tooltip on hover
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: {
            // Convert newlines to HTML line breaks for per-package lines without affecting other modules
            var html = root.tooltipText
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/\n/g, "<br/>")
            // Set tooltip height to 90% of screen height
            var screenHeight = Screen.height
            C.Tooltip.show(root, html, false, { maxHeight: screenHeight })
        }
        onExited: C.Tooltip.hide()
    }
}
