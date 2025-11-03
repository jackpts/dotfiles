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
        color: C.Theme.cpu
        trackColor: C.Theme.track
        value: percent/100
        label: percent + "%"
    }

    Process {
        id: proc
        command: ["bash","-lc","$HOME/dotfiles/scripts/cpu_with_temp.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj && obj.text) {
                        var m = /([0-9]+)/.exec(obj.text)
                        root.percent = m ? parseInt(m[1]) : 0
                    }
                    if (obj && obj.tooltip) root.tip = obj.tooltip
                } catch (e) {}
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: proc.running = true }

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                C.Tooltip.show(gauge, "CPU: " + percent + "%" + (tip ? "\n" + tip : ""))
            } else {
                C.Tooltip.hide()
            }
        }
    }

    Process { id: run }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: { run.command = ["bash","-lc","kitty -e htop"]; run.running = true }
        onEntered: { C.Tooltip.show(gauge, "CPU: " + percent + "%" + (tip ? "\n" + tip : "")) }
        onExited: { C.Tooltip.hide() }
    }
}
