import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 35; height: 50
    property bool hasDevices: false
    property int numConnections: 0
    property string displayText: ""
    property string tooltipText: ""

    function icon() {
        return hasDevices ? "" : "󰂲";
    }

    Process {
        id: proc
        command: ["bash", "-lc",
            "macs=$(bluetoothctl devices Connected | grep -oP 'Device\\s+([0-9A-F:]{17})' | awk '{print $2}' | sort -u); " +
            "if [ -z \"$macs\" ]; then echo 'none'; exit 0; fi; " +
            "controller=$(bluetoothctl show | grep 'Alias:' | awk '{print substr($0, index($0,$2))}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "num=0; parts=(); tips=(); " +
            "for mac in $macs; do " +
            "  if [[ \"$mac\" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then " +
            "    num=$((num + 1)); " +
            "    alias=$(bluetoothctl info \"$mac\" | grep 'Alias:' | awk '{print substr($0, index($0,$2))}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "    [ -z \"$alias\" ] && alias=\"Unknown Device ($mac)\"; " +
            "    batt=''; " +
            "    dbus_path=\"/org/bluez/hci0/dev_${mac//:/_}\"; " +
            "    batt=$(gdbus call --system --dest org.bluez --object-path \"$dbus_path\" --method org.freedesktop.DBus.Properties.Get org.bluez.Battery1 Percentage 2>/dev/null | grep -oP '0x[0-9A-Fa-f]+' | xargs printf '%d'); " +
            "    if [ -z \"$batt\" ]; then " +
            "      batt=$(bluetoothctl info \"$mac\" | awk -F '[()]' '/Battery Percentage:/ {print $2}' | grep -oP '\\d+'); " +
            "    fi; " +
            "    if [ -z \"$batt\" ]; then " +
            "      upower_path=$(upower -e | grep -i \"${mac//:/_}\"); " +
            "      if [ -n \"$upower_path\" ]; then " +
            "        batt=$(upower -i \"$upower_path\" | grep 'percentage:' | awk '{print $2}' | tr -d '%'); " +
            "      fi; " +
            "    fi; " +
            "    if [ -z \"$batt\" ]; then " +
            "      for sysfs in /sys/class/power_supply/*/; do " +
            "        if [ -f \"${sysfs}device/address\" ]; then " +
            "          addr=$(cat \"${sysfs}device/address\" 2>/dev/null | tr '[:lower:]' '[:upper:]'); " +
            "          if [ \"$addr\" = \"$mac\" ] && [ -f \"${sysfs}capacity\" ]; then " +
            "            batt=$(cat \"${sysfs}capacity\" 2>/dev/null); " +
            "            break; " +
            "          fi; " +
            "        fi; " +
            "      done; " +
            "    fi; " +
            "    if [ -z \"$batt\" ]; then " +
            "      if [ -x /usr/bin/libre\ pods ]; then " +
            "        batt=$(libre\ pods --battery $mac 2>/dev/null | grep -oP '\\d+'); " +
            "      fi; " +
            "    fi; " +
            "    if [ -n \"$batt\" ] && [ \"$batt\" -gt 0 ] 2>/dev/null; then " +
            "      parts+=(\"${batt}%\"); " +
            "      tips+=(\"${alias}@${batt}%\"); " +
            "    else " +
            "      parts+=(\"󰂯\"); " +
            "      tips+=(\"${alias}@NA\"); " +
            "    fi; " +
            "  fi; " +
            "done; " +
            "IFS='|'; echo \"${num}|${controller}|${parts[*]}|${tips[*]}\""
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim()
                if (out === "none") {
                    root.hasDevices = false
                    root.numConnections = 0
                    root.displayText = ""
                    root.tooltipText = "No Bluetooth devices connected or Bluetooth is off"
                } else {
                    var parts = out.split("|")
                    if (parts.length >= 4) {
                        root.numConnections = parseInt(parts[0]) || 0
                        var controller = parts[1]
                        var displays = parts[2].split(",")
                        var tips = parts[3].split(",")
                        
                        root.hasDevices = root.numConnections > 0
                        root.displayText = displays.join(" | ")
                        
                        var lines = []
                        if (controller && controller.length) lines.push(controller)
                        lines.push(root.numConnections + " connected")
                        for (var i = 0; i < tips.length; i++) {
                            var tip = tips[i].split("@")
                            if (tip.length === 2) {
                                if (tip[1] !== "NA") {
                                    lines.push(tip[0] + "\t  " + tip[1])
                                } else {
                                    lines.push(tip[0])
                                }
                            }
                        }
                        root.tooltipText = lines.join("\n")
                    }
                }
                if (area.containsMouse) {
                    C.Tooltip.show(root, root.tooltipText)
                }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }
    
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: { run.command = ["bash", "-lc", "blueman-manager"]; run.running = true }
        onEntered: {
            C.Tooltip.show(root, root.tooltipText)
            hoverRefresh.restart()
        }
        onExited: C.Tooltip.hide()
    }

    Timer {
        id: hoverRefresh
        interval: 1000; running: false; repeat: true
        onTriggered: {
            if (area.containsMouse) {
                C.Tooltip.show(root, root.tooltipText)
            } else {
                hoverRefresh.stop()
            }
        }
    }
    
        Text {
            anchors.centerIn: parent
            text: root.hasDevices ? root.displayText : "󰂲"
            color: root.hasDevices ? C.Theme.bluetoothActive : C.Theme.bluetoothInactive
            font.pixelSize: 16
            enabled: false  // Make text transparent to mouse events
        }
}
