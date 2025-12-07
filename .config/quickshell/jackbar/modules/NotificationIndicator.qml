import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 50
    property string bellIcon: ""
    property string countText: "0"

    // Poll unread count using a one-shot command that exits
    Process {
        id: countProc
        command: ["bash", "-lc", "swaync-client -c || echo 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = (this.text || "").trim()
                // Expect a number; fallback to 0
                var m = raw.match(/^(\d+)$/)
                var cnt = m ? m[1] : "0"
                root.countText = cnt
                // Icon: bell with notification glyph if any, otherwise outline bell
                root.bellIcon = (parseInt(cnt) > 0) ? "󱅫" : ""
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: countProc.running = true }

    Process { id: run }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                run.command = ["bash", "-lc", "sleep 0.1 && swaync-client -t -sw"]
                run.running = true
            } else if (mouse.button === Qt.RightButton) {
                run.command = ["bash", "-lc", "sleep 0.1 && swaync-client -d -sw"]
                run.running = true
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.countText
            color: C.Theme.text
            font.pixelSize: 15
            font.bold: true
            enabled: false
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.bellIcon
            color: C.Theme.text
            font.pixelSize: 18
            enabled: false
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
