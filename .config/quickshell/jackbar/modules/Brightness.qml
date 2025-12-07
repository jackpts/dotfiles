/*------------------------------
--- Brightness.qml by andrel ---
------------------------------*/

import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32; height: 50
    property int maxBrightness: 100
    property int currentBrightness: 0
    readonly property real brightness: maxBrightness > 0 ? currentBrightness / maxBrightness : 0

    function icon() {
        var b = brightness
        if (b === 0) return "󰃞"  // brightness-off
        if (b <= 0.33) return "󰃟"  // brightness-low
        if (b <= 0.66) return "󰃝"  // brightness-medium
        return "󰃠"  // brightness-high
    }

    // Get the maximum brightness value
    Process {
        id: maxBrightnessProc
        running: true
        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text)
                if (!isNaN(val) && val > 0) {
                    root.maxBrightness = val
                }
            }
        }
    }

    // Get the current brightness value
    Process {
        id: getCurrentBrightness
        running: true
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text)
                if (!isNaN(val)) {
                    root.currentBrightness = val
                }
                if (area.containsMouse) {
                    updateTooltip()
                }
            }
        }
    }

    // Listen for backlight events and update the current brightness on UDEV event
    Process {
        running: true
        command: ["udevadm", "monitor", "--subsystem-match=backlight"]
        stdout: SplitParser {
            splitMarker: "UDEV"
            onRead: getCurrentBrightness.running = true
        }
    }

    function updateTooltip() {
        var percent = Math.round(brightness * 100)
        var tooltip = "Brightness: " + percent + "%"
        tooltip += "<br>Current: " + currentBrightness
        tooltip += "<br>Max: " + maxBrightness
        C.Tooltip.show(root, tooltip)
    }

    Process { id: setBrightnessProc }

    function adjustBrightness(delta) {
        // Adjust by delta percentage (e.g., +5 or -5)
        var newPercent = Math.round(brightness * 100) + delta
        newPercent = Math.max(1, Math.min(100, newPercent))  // Clamp between 1-100
        setBrightnessProc.command = ["brightnessctl", "set", newPercent + "%"]
        setBrightnessProc.running = true
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: updateTooltip()
        onExited: C.Tooltip.hide()
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                adjustBrightness(5)  // Scroll up = increase 5%
            } else {
                adjustBrightness(-5)  // Scroll down = decrease 5%
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon()
        color: C.Theme.text
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
}
