import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: C.Theme.panelHeight
    property int percent: 0
    property string status: "Unknown"
    property int health: 0
    property string capacity: "Unknown"
    property string powerMode: "Unknown"
    property real powerWatts: 0
    property real energyNowWh: 0
    property real energyFullWh: 0
    property string powerProfile: ""
    property string availableProfiles: "power-saver,balanced,performance"
    property bool menuOpen: false
    property double _menuClosedAt: 0
    readonly property string profileScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/modules/power-profile.sh"
    readonly property var profileOptions: [
        { id: "power-saver", label: "Power-saver", icon: "󰌪" },
        { id: "balanced", label: "Balanced", icon: "󰾅" },
        { id: "performance", label: "Performance", icon: "󰓅" }
    ]

    function statusKey() {
        return (status || "").toLowerCase().replace(/_/g, " ").trim()
    }
    function isCharging() {
        return statusKey() === "charging"
    }
    function isDischarging() {
        return statusKey() === "discharging"
    }
    function hasProfile(id) {
        return ("," + availableProfiles + ",").indexOf("," + id + ",") !== -1
    }
    function profileLabel() {
        if (powerProfile === "power-saver") return "Power-saver"
        if (powerProfile === "performance") return "Performance"
        if (powerProfile === "balanced") return "Balanced"
        if (powerProfile === "custom") return "Custom"
        if (powerMode !== "Unknown" && powerMode !== "") return powerMode
        return ""
    }
    function applyProfileOutput(text) {
        var parts = (text || "").trim().split("|")
        if (parts.length >= 1 && parts[0].length)
            root.powerProfile = parts[0]
        if (parts.length >= 2 && parts[1].length)
            root.availableProfiles = parts[1]
    }
    function refreshProfile() {
        if (profileGet.running)
            profileGet.running = false
        profileGet.running = true
    }
    function setProfile(id) {
        if (id === root.powerProfile) {
            root.menuOpen = false
            return
        }
        profileSet.command = [root.profileScript, "set", id]
        profileSet.running = false
        profileSet.running = true
    }
    function toggleMenu() {
        if (Date.now() - root._menuClosedAt < 250)
            return
        root.menuOpen = !root.menuOpen
        if (root.menuOpen) {
            C.Tooltip.hide()
            refreshProfile()
        }
    }
    function showHoverTooltip() {
        if (root.menuOpen || !area.containsMouse)
            return
        C.Tooltip.show(root, buildTooltip())
    }

    function formatDuration(hours) {
        if (!isFinite(hours) || hours <= 0)
            return ""
        var totalMins = Math.round(hours * 60)
        if (totalMins < 1)
            return "<1m"
        var h = Math.floor(totalMins / 60)
        var m = totalMins % 60
        if (h > 0)
            return h + "h " + m + "m"
        return m + "m"
    }

    function timeLeftText() {
        if (powerWatts < 0.1)
            return ""
        if (isDischarging() && energyNowWh > 0)
            return formatDuration(energyNowWh / powerWatts)
        if (isCharging() && energyFullWh > energyNowWh)
            return formatDuration((energyFullWh - energyNowWh) / powerWatts)
        return ""
    }

    function buildTooltip() {
        var tooltip = "Battery"
        tooltip += "<br>Charge: " + percent + "%"
        tooltip += "<br>Status: " + status
        var eta = timeLeftText()
        var timeLabel = isCharging() ? "Time to full" : "Time left"
        tooltip += "<br>" + timeLabel + ": " + (eta.length ? eta : "—")
        var powerLabel = isCharging() ? "Charging" : (isDischarging() ? "Discharging" : "Power")
        tooltip += "<br>" + powerLabel + ": " + powerWatts.toFixed(1) + "W"
        if (health > 0) {
            tooltip += "<br>Health: " + health + "%"
        }
        if (capacity !== "Unknown" && capacity !== "") {
            tooltip += "<br>Capacity: " + capacity
        }
        var profile = profileLabel()
        if (profile.length)
            tooltip += "<br>Profile: " + profile
        else if (powerMode !== "Unknown" && powerMode !== "")
            tooltip += "<br>Mode: " + powerMode
        tooltip += "<br>Click: power profile"
        return tooltip
    }

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: C.Theme.scale(28)
        thickness: C.Theme.scale(4)
        color: isCharging() ? C.Theme.batteryCharging : (percent <= 15 ? C.Theme.batteryCritical : C.Theme.batteryOk)
        trackColor: C.Theme.track
        value: percent/100
        label: percent + "%"
    }

    property bool _initialized: false
    property bool _notified20: false
    property bool _notified15: false
    property bool _notified10: false
    property bool _wasCharging: false

    Process { id: batNotify }
    function checkBattery() {
        if (!_initialized) return
        var charging = isCharging()

        if (charging && !_wasCharging) {
            _notified20 = false; _notified15 = false; _notified10 = false
        }
        _wasCharging = charging

        if (charging) return
        if (percent <= 10 && !_notified10) {
            _notified10 = true
            batNotify.command = ["notify-send", "-u", "critical", "-i", "battery-low", "Battery Critical", "Battery at " + percent + "%! Plug in now."]
            batNotify.running = true
        } else if (percent <= 15 && !_notified15) {
            _notified15 = true
            batNotify.command = ["notify-send", "-u", "critical", "-i", "battery-low", "Battery Low", "Battery at " + percent + "%! Charge soon."]
            batNotify.running = true
        } else if (percent <= 20 && !_notified20) {
            _notified20 = true
            batNotify.command = ["notify-send", "-u", "normal", "-i", "battery", "Battery Warning", "Battery at " + percent + "%"]
            batNotify.running = true
        }
    }

    // Read from sysfs first for efficiency
    Process { id: cap; stdout: StdioCollector { onStreamFinished: { var v = parseInt(this.text); if (!isNaN(v)) { root.percent = v; root._initialized = true } } } }
    Process { id: stat; stdout: StdioCollector { onStreamFinished: { root.status = this.text.trim() || root.status } } }
    Process { id: healthProc; stdout: StdioCollector { onStreamFinished: { var v = parseInt(this.text); root.health = isNaN(v) ? root.health : v } } }
    Process { id: capacityProc; stdout: StdioCollector { onStreamFinished: { root.capacity = this.text.trim() || root.capacity } } }
    Process { id: powerModeProc; stdout: StdioCollector { onStreamFinished: { root.powerMode = this.text.trim() || root.powerMode } } }
    Process {
        id: rateProc
        command: ["bash", "-lc", "bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); [ -z \"$bat\" ] && echo '0|0|0' && exit 0; pw=$(cat \"$bat/power_now\" 2>/dev/null | head -n1); en=$(cat \"$bat/energy_now\" 2>/dev/null | head -n1); ef=$(cat \"$bat/energy_full\" 2>/dev/null | head -n1); if [ -z \"$pw\" ] || [ \"$pw\" = \"0\" ]; then cur=$(cat \"$bat/current_now\" 2>/dev/null | head -n1); volt=$(cat \"$bat/voltage_now\" 2>/dev/null | head -n1); if [ -n \"$cur\" ] && [ -n \"$volt\" ]; then pw=$((cur * volt / 1000000)); fi; fi; echo \"${pw:-0}|${en:-0}|${ef:-0}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|")
                if (parts.length >= 1) {
                    var uw = parseFloat(parts[0])
                    root.powerWatts = isNaN(uw) ? 0 : Math.abs(uw) / 1000000.0
                }
                if (parts.length >= 2) {
                    var now = parseFloat(parts[1])
                    root.energyNowWh = isNaN(now) ? 0 : now / 1000000.0
                }
                if (parts.length >= 3) {
                    var full = parseFloat(parts[2])
                    root.energyFullWh = isNaN(full) ? 0 : full / 1000000.0
                }
                showHoverTooltip()
            }
        }
    }

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
                        if (m) { root.percent = parseInt(m[1]); root._initialized = true }
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
        refreshRate()
        refreshProfile()
        upowerProc.command = ["bash","-lc","dev=$(upower -e 2>/dev/null | grep -m1 BAT || true); if [ -n \"$dev\" ]; then upower -i \"$dev\"; fi"]; upowerProc.running = true
        checkBattery()
    }

    function refreshRate() {
        rateProc.running = false
        rateProc.running = true
    }

    Process {
        id: profileGet
        command: [root.profileScript, "get"]
        stdout: StdioCollector {
            onStreamFinished: applyProfileOutput(this.text)
        }
    }
    Process {
        id: profileSet
        stdout: StdioCollector {
            onStreamFinished: applyProfileOutput(this.text)
        }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.menuOpen = false
                return
            }
            batNotify.command = ["notify-send", "-u", "normal", "-i", "battery", "Power profile", "Could not switch profile (needs power-profiles-daemon, or polkit for ACPI)."]
            batNotify.running = true
        }
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onEntered: {
            refreshRate()
            showHoverTooltip()
        }
        onExited: {
            if (!root.menuOpen)
                C.Tooltip.hide()
        }
        onClicked: toggleMenu()
    }

    PopupWindow {
        id: profilePopup
        visible: root.menuOpen
        grabFocus: true
        color: "transparent"
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.margins.top: 6
        implicitWidth: profileBox.implicitWidth
        implicitHeight: profileBox.implicitHeight
        onVisibleChanged: {
            if (visible)
                return
            root.menuOpen = false
            root._menuClosedAt = Date.now()
        }

        Rectangle {
            id: profileBox
            implicitWidth: profileCol.implicitWidth + 20
            implicitHeight: profileCol.implicitHeight + 20
            color: C.Theme.tooltipBg
            border.color: C.Theme.tooltipBorder
            border.width: 0

            Column {
                id: profileCol
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "POWER PROFILE"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    font.bold: true
                }

                Row {
                    spacing: 8

                    Repeater {
                        model: root.profileOptions
                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            visible: root.hasProfile(modelData.id)
                            width: 112
                            height: 56
                            radius: 2
                            color: active ? "#33215fad" : (btnHover.containsMouse ? "#22ffffff" : "#18ffffff")
                            border.width: active ? 1 : 0
                            border.color: C.Theme.batteryOk
                            readonly property bool active: root.powerProfile === modelData.id

                            MouseArea {
                                id: btnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.setProfile(modelData.id)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: btn.active ? C.Theme.text : C.Theme.textMuted
                                    font.pixelSize: C.Theme.fontIcon
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: btn.active ? C.Theme.text : C.Theme.textMuted
                                    font.pixelSize: C.Theme.fontXs
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
