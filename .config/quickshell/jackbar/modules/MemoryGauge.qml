import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property int percent: 0
    property string tip: ""

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        // color: C.Theme.memory
        color: C.Theme.memoryGauge
        trackColor: C.Theme.track
        value: percent/100
        label: percent + "%"
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
    Timer { interval: 2000; running: true; repeat: true; onTriggered: proc.running = true }

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
