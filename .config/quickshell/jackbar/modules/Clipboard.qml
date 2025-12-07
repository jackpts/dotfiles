import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 24; height: 50

    Process { id: showCopyq }
    Process { id: checkCopyq }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // First check if copyq is running
            checkCopyq.command = ["pgrep", "-x", "copyq"]
            checkCopyq.running = true
        }
    }

    Connections {
        target: checkCopyq
        function onExited() {
            if (checkCopyq.exitCode !== 0) {
                // copyq not running, start it first
                showCopyq.command = ["bash", "-c", "copyq & sleep 0.2 && copyq toggle"]
            } else {
                // copyq is running, just toggle
                showCopyq.command = ["copyq", "toggle"]
            }
            showCopyq.running = true
        }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        color: C.Theme.text
        font.pixelSize: 18
        enabled: false // Let MouseArea handle clicks
    }
}
