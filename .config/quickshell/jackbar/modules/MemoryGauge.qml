import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 50
    property int percent: 0
    property string tip: ""

    function fmtGiBFromKB(kb) {
        return (kb / 1024 / 1024).toFixed(1) + " GiB"
    }

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
        command: ["bash","-lc","awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} /MemFree:/ {f=$2} END { if (!a) a=f; print t \":\" a }' /proc/meminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var parts = s.split(":")
                if (parts.length >= 2) {
                    var totalKb = parseInt(parts[0])
                    var availKb = parseInt(parts[1])
                    if (!isNaN(totalKb) && !isNaN(availKb) && totalKb > 0) {
                        var usedKb = Math.max(0, totalKb - availKb)
                        root.percent = Math.max(0, Math.min(100, Math.round(usedKb * 100 / totalKb)))
                        root.tip = "Used: " + fmtGiBFromKB(usedKb) + " / " + fmtGiBFromKB(totalKb) + "\n" +
                            "Available: " + fmtGiBFromKB(availKb)
                    }
                }
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
