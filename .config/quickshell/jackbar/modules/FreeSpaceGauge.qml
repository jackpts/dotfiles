
import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 50
    property int freePercent: 0
    // Show occupied (used) percent in the gauge while keeping free info for tooltip
    property int usedPercent: 100 - freePercent
    property string tip: ""
    property string rootTip: ""

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        // Keep color logic based on free space thresholds
        color: freePercent < 10 ? C.Theme.freeLow : C.Theme.freeOk
        trackColor: C.Theme.track
        // Show occupied space in the chart
        value: usedPercent/100
        // Label matches the chart (occupied percent)
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
                    var p = total > 0 ? Math.floor(avail*100/total) : 0
                    root.freePercent = p
                    root.tip = "Home free: " + p + "% (" + fmtGB(avail) + "/" + fmtGB(total) + ")"
                }
            }
        }
    }
    
    Process {
        id: rootProc
        command: ["bash","-lc","df -B1 / | awk 'NR==2 { print $2\":\"$3\":\"$4 }'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var parts = s.split(":")
                if (parts.length >= 3) {
                    var total = parseFloat(parts[0]); var used = parseFloat(parts[1]); var avail = parseFloat(parts[2]);
                    var p = total > 0 ? Math.floor(avail*100/total) : 0
                    root.rootTip = "Root free: " + p + "% (" + fmtGB(avail) + "/" + fmtGB(total) + ")"
                }
            }
        }
    }
Timer { 
    interval: 30000; 
    running: true; 
    repeat: true; 
    onTriggered: {
        proc.running = true
        rootProc.running = true
    }
}

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
                var tooltipText = ""
                if (tip) tooltipText = tip
                if (rootTip) tooltipText += "<br>" + rootTip
                C.Tooltip.show(gauge, tooltipText)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
