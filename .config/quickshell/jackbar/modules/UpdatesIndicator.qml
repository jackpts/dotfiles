import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 64; height: 40
    property string textValue: "0 󰚰"
    property string statusClass: "ok" // "ok" or "updates"

    Process {
        id: proc
        command: ["bash","-lc","$HOME/scripts/garuda_updates.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj && obj.text) root.textValue = obj.text
                    if (obj && obj.class) root.statusClass = obj.class
                } catch (e) {}
            }
        }
    }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        onClicked: {
            run.command = ["bash","-lc","kitty -e bash -lc 'sudo pacman -Syu && paru -Sua --noconfirm; notify-send \"Update complete\"; read -n 1 -s -p \"Press any key to close\"' "]
            run.running = true
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: textValue
        color: statusClass === "updates" ? C.Theme.updatesAvailable : C.Theme.updatesNone
        font.pixelSize: 14
        enabled: false  // Make text transparent to mouse events
    }
}
