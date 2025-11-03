import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property int percent: 0
    property string status: "Unknown"

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        color: status.indexOf("Charging") !== -1 ? C.Theme.batteryCharging : (percent <= 15 ? C.Theme.batteryCritical : C.Theme.batteryOk)
        trackColor: C.Theme.track
        value: percent/100
        label: percent + "%"
    }

    // Read from sysfs first for efficiency
    Process { id: cap; stdout: StdioCollector { onStreamFinished: { var v = parseInt(this.text); root.percent = isNaN(v) ? root.percent : v } } }
    Process { id: stat; stdout: StdioCollector { onStreamFinished: { root.status = this.text.trim() || root.status } } }

    // Fallback updater via upower if sysfs is unavailable
    Process {
        id: upowerProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split(/\n/)
                for (var i=0;i<lines.length;i++) {
                    var line = lines[i]
                    if (line.indexOf("percentage:") !== -1) {
                        var m = /([0-9]+)%/.exec(line)
                        if (m) root.percent = parseInt(m[1])
                    } else if (line.indexOf("state:") !== -1) {
                        root.status = line.split(":").pop().trim()
                    }
                }
            }
        }
    }

    function update() {
        cap.command = ["bash","-lc","cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1"]; cap.running = true
        stat.command = ["bash","-lc","cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1"]; stat.running = true
        upowerProc.command = ["bash","-lc","dev=$(upower -e 2>/dev/null | grep -m1 BAT || true); if [ -n \"$dev\" ]; then upower -i \"$dev\"; fi"]; upowerProc.running = true
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                C.Tooltip.show(gauge, "Battery: " + percent + "%\nStatus: " + status)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
