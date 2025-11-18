import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property int percent: 0
    property string status: "Unknown"
    property int health: 0
    property string capacity: "Unknown"
    property string powerMode: "Unknown"

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
    Process { id: healthProc; stdout: StdioCollector { onStreamFinished: { var v = parseInt(this.text); root.health = isNaN(v) ? root.health : v } } }
    Process { id: capacityProc; stdout: StdioCollector { onStreamFinished: { root.capacity = this.text.trim() || root.capacity } } }
    Process { id: powerModeProc; stdout: StdioCollector { onStreamFinished: { root.powerMode = this.text.trim() || root.powerMode } } }

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
        healthProc.command = ["bash","-lc","full=$(cat /sys/class/power_supply/BAT*/energy_full 2>/dev/null | head -n1); design=$(cat /sys/class/power_supply/BAT*/energy_full_design 2>/dev/null | head -n1); if [ -n \"$full\" ] && [ -n \"$design\" ] && [ \"$design\" -gt 0 ]; then echo $(($full * 100 / $design)); fi"]; healthProc.running = true
        capacityProc.command = ["bash","-lc","cat /sys/class/power_supply/BAT*/capacity_level 2>/dev/null | head -n1"]; capacityProc.running = true
        powerModeProc.command = ["bash","-lc","mode=$(cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null | head -n1); if [ -n \"$mode\" ]; then echo $mode; elif [ -f /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor ]; then cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | head -n1; fi"]; powerModeProc.running = true
        upowerProc.command = ["bash","-lc","dev=$(upower -e 2>/dev/null | grep -m1 BAT || true); if [ -n \"$dev\" ]; then upower -i \"$dev\"; fi"]; upowerProc.running = true
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                var tooltip = "Battery"
                tooltip += "<br>Charge: " + percent + "%"
                tooltip += "<br>Status: " + status
                if (health > 0) {
                    tooltip += "<br>Health: " + health + "%"
                }
                if (capacity !== "Unknown" && capacity !== "") {
                    tooltip += "<br>Capacity: " + capacity
                }
                if (powerMode !== "Unknown" && powerMode !== "") {
                    tooltip += "<br>Mode: " + powerMode
                }
                C.Tooltip.show(gauge, tooltip)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
