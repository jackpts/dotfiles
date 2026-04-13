/*------------------------------
--- Brightness.qml by andrel ---
------------------------------*/

import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32; height: C.Theme.panelHeight
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

    Item {
        id: brightnessGauge
        anchors.centerIn: parent
        width: C.Theme.scale(24)
        height: width
        property real percent: root.brightness

        Canvas {
            id: donutCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.reset()
                ctx.clearRect(0, 0, w, h)

                var cx = w / 2
                var cy = h / 2
                var outer = Math.min(w, h) / 2
                var inner = outer * 0.35
                var trackThickness = C.Theme.scale(3)
                var segments = Math.max(1, Math.round(brightnessGauge.percent * 48))

                // Draw outer ring background
                ctx.strokeStyle = C.Theme.track
                ctx.lineWidth = trackThickness
                ctx.beginPath()
                ctx.arc(cx, cy, (inner + outer) / 2, 0, Math.PI * 2)
                ctx.stroke()

                if (segments <= 0)
                    return

                ctx.lineWidth = C.Theme.scale(2)
                ctx.strokeStyle = C.Theme.text
                var startAngle = -Math.PI / 2
                var sweep = Math.PI * 2 * brightnessGauge.percent
                var step = sweep / segments
                for (var i = 0; i < segments; i++) {
                    var angle = startAngle + i * step
                    var cos = Math.cos(angle)
                    var sin = Math.sin(angle)
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.lineTo(cx + cos * outer, cy + sin * outer)
                    ctx.stroke()
                }
            }
        }

        onPercentChanged: donutCanvas.requestPaint()
        Component.onCompleted: donutCanvas.requestPaint()
    }
}
