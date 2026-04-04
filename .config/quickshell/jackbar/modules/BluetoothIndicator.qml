import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: Math.max(contentRow.implicitWidth + C.Theme.scale(8), C.Theme.scale(50))
    height: C.Theme.panelHeight
    property bool hasDevices: false
    property int numConnections: 0
    property string displayText: ""
    property string tooltipText: ""
    property bool bluetoothPowered: false
    property var batteryValues: []
    property var panelSegments: []

    function icon() {
        return hasDevices ? "" : "󰂲";
    }

    function updatePanelSegments() {
        var iconChar = root.bluetoothPowered ? "󰂯" : "󰂲"
        var segments = [iconChar]
        if (root.batteryValues && root.batteryValues.length) {
            for (var i = 0; i < root.batteryValues.length; i++) {
                segments.push(root.batteryValues[i] + "%")
            }
        }
        root.panelSegments = segments
    }

    onBatteryValuesChanged: updatePanelSegments()
    onBluetoothPoweredChanged: updatePanelSegments()
    Component.onCompleted: updatePanelSegments()

    Process {
        id: proc
        command: ["bash", "-lc", `
            macs=\$(bluetoothctl devices Connected | grep -oP 'Device\\s+([0-9A-F:]{17})' | awk '{print \$2}' | sort -u)
            if [ -z "\$macs" ]; then
                echo "COUNT=0"
                echo "CONTROLLER=none"
                exit 0
            fi

            num=0

            for mac in \$macs; do
                if [[ "\$mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
                    num=\$((num + 1))
                    alias=\$(bluetoothctl info "\$mac" | grep 'Alias:' | sed 's/^[[:space:]]*Alias:[[:space:]]*//')
                    [ -z "\$alias" ] && alias="Unknown Device"

                    batt=""
                    # Try BlueZ D-Bus first - returns (<byte 0x41>,) format
                    dbus_path="/org/bluez/hci0/dev_\${mac//:/_}"
                    dbus_raw=\$(gdbus call --system --dest org.bluez --object-path "\$dbus_path" --method org.freedesktop.DBus.Properties.Get org.bluez.Battery1 Percentage 2>/dev/null)
                    if [ -n "\$dbus_raw" ]; then
                        # Extract hex byte value like 0x41 from (<byte 0x41>,)
                        hex_val=\$(echo "\$dbus_raw" | grep -oP '0x[0-9a-fA-F]+')
                        if [ -n "\$hex_val" ]; then
                            # Convert hex to decimal
                            batt=\$((hex_val))
                        fi
                    fi

                    # Fallback: upower
                    if [ -z "\$batt" ]; then
                        upower_path=\$(upower -e | grep -i "\${mac//:/_}" | head -1)
                        if [ -n "\$upower_path" ]; then
                            batt=\$(upower -i "\$upower_path" | grep 'percentage:' | awk '{print \$2}' | tr -d '%')
                        fi
                    fi

                    # Fallback: sysfs
                    if [ -z "\$batt" ]; then
                        for sysfs in /sys/class/power_supply/*/; do
                            if [ -f "\${sysfs}device/address" ]; then
                                addr=\$(cat "\${sysfs}device/address" 2>/dev/null | tr '[:lower:]' '[:upper:]')
                                if [ "\$addr" = "\$mac" ] && [ -f "\${sysfs}capacity" ]; then
                                    batt=\$(cat "\${sysfs}capacity" 2>/dev/null)
                                    break
                                fi
                            fi
                        done
                    fi

                    if [ -n "\$batt" ] && [ "\$batt" -gt 0 ] 2>/dev/null; then
                        echo "DEVICE:\${alias}:\${batt}"
                    else
                        echo "DEVICE:\${alias}:-"
                    fi
                fi
            done
            echo "COUNT:\${num}"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                var controller = "main";
                var devices = [];
                var batteryList = [];
                var count = 0;

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("COUNT:")) {
                        count = parseInt(line.substring(6)) || 0;
                    } else if (line.startsWith("DEVICE:")) {
                        var rest = line.substring(7);
                        var lastColon = rest.lastIndexOf(":");
                        if (lastColon > 0) {
                            var name = rest.substring(0, lastColon);
                            var batt = rest.substring(lastColon + 1);
                            devices.push({name: name, battery: batt});
                            if (batt !== "-" && batt !== "") {
                                batteryList.push(parseInt(batt));
                            }
                        }
                    }
                }

                root.numConnections = count;
                root.hasDevices = count > 0;

                if (count === 0) {
                    root.displayText = "";
                    root.tooltipText = root.bluetoothPowered ? "No Bluetooth devices connected" : "Bluetooth is off";
                    root.batteryValues = [];
                } else {
                    var displays = [];
                    for (var j = 0; j < devices.length; j++) {
                        if (devices[j].battery !== "-") {
                            displays.push(devices[j].battery + "%");
                        } else {
                            displays.push("󰂯");
                        }
                    }
                    root.displayText = displays.join(" | ");

                    var tipLines = [];
                    tipLines.push("<b>Connected Devices:</b> (" + count + ")<br>");
                    tipLines.push("");
                    for (var k = 0; k < devices.length; k++) {
                        var d = devices[k];
                        if (d.battery !== "-" && d.battery !== "") {
                            tipLines.push(d.name + " - " + d.battery + "%");
                        } else {
                            tipLines.push(d.name + " - N/A");
                        }
                        if (k < devices.length - 1) {
                            tipLines.push("<br>");
                        }
                    }
                    root.tooltipText = tipLines.join("\n");
                    root.batteryValues = batteryList;
                }

                if (area.containsMouse) {
                    C.Tooltip.show(root, root.tooltipText);
                }
            }
        }
    }

    Process {
        id: poweredProc
        command: ["bash", "-lc", "bluetoothctl show | awk -F': ' '/Powered:/ {print tolower($2)}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothPowered = this.text.indexOf("yes") !== -1
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            proc.running = true
            poweredProc.running = true
        }
    }

    Process {
        id: run
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            run.command = ["bash", "-lc", "blueman-manager"];
            run.running = true;
        }
        onEntered: {
            C.Tooltip.show(root, root.tooltipText);
            hoverRefresh.restart();
        }
        onExited: C.Tooltip.hide()
    }

    Timer {
        id: hoverRefresh
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if (area.containsMouse) {
                C.Tooltip.show(root, root.tooltipText);
            } else {
                hoverRefresh.stop();
            }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0
        Repeater {
            model: root.panelSegments
            delegate: Text {
                text: index === 0 ? modelData : "|" + modelData
                color: index === 0 ? (root.bluetoothPowered ? C.Theme.bluetoothActive : C.Theme.bluetoothInactive) : C.Theme.bluetoothActive
                font.pixelSize: index === 0 ? C.Theme.fontIcon : C.Theme.fontSm
                font.bold: index !== 0
                enabled: false
            }
        }
    }
}
