import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: C.Theme.panelHeight
    property int percent: 0
    property string tip: ""
    property int _lastNotified: -1

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        color: C.Theme.memoryGauge
        trackColor: C.Theme.track
        value: percent/100
        label: percent + "%"
    }

    Process {
        id: notifyProc
    }
    function checkRam() {
        if (percent >= 90 && _lastNotified < 90) {
            _lastNotified = percent
            notifyProc.command = ["notify-send", "-u", "critical", "-i", "memory", "RAM Usage Warning", "Memory usage at " + percent + "%!"]
            notifyProc.running = true
        } else if (percent < 80) {
            _lastNotified = -1
        }
    }

    Process {
        id: proc
        command: ["bash","-lc","$HOME/dotfiles/scripts/ram_usage_mb.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj && obj.percentage !== undefined) {
                        root.percent = parseInt(obj.percentage)
                        root.tip = obj.tooltip || ""
                    }
                } catch (e) {}
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: { proc.running = true; checkRam() } }

    Process { id: run }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","missioncenter || gnome-system-monitor"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","resources || btop"]; run.running = true } }
    }

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                var tooltipText = "Memory: " + percent + "%"
                if (tip) {
                    // Convert both escaped newlines (\\n) and literal newlines (\n) to HTML line breaks
                    tooltipText += "<br>" + tip.replace(/\\n/g, "<br>").replace(/\n/g, "<br>")
                }
                C.Tooltip.show(gauge, tooltipText)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
