import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    // Percentage of free space
    property int freePercent: 0
    // Percentage of used/occupied space (for chart display)
    property int usedPercent: 0
    property string tip: ""

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        // Keep color logic based on free space remaining
        color: freePercent < 10 ? C.Theme.freeLow : C.Theme.freeOk
        trackColor: C.Theme.track
        // Show occupied percentage in the gauge
        value: usedPercent/100
        label: usedPercent + "%"
    }

    function fmtGB(bytes) { return Math.round(bytes/1024/1024/1024) + " GB" }

    Process {
        id: proc
        command: ["bash","-lc","df -B1 /home | awk 'NR==2 { print $2\":\"$3\":\"$4 }'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var parts = s.split(":")
                if (parts.length >= 3) {
                    var total = parseFloat(parts[0]); var used = parseFloat(parts[1]); var avail = parseFloat(parts[2]);
                    var freeP = total > 0 ? Math.floor(avail*100/total) : 0
                    var usedP = total > 0 ? Math.floor(used*100/total) : 0
                    root.freePercent = freeP
                    root.usedPercent = usedP
                    root.tip = "Free: " + fmtGB(avail) + " / " + fmtGB(total)
                }
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            run.command = ["bash", "-lc", "kitty --class disk-info -e sh -c 'dysk; read -p \"Press Enter\"'"]
            run.running = true
        }
    }

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                var tooltipText = "Home free: " + freePercent + "%"
                if (tip) tooltipText += "<br>" + tip
                C.Tooltip.show(gauge, tooltipText)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
