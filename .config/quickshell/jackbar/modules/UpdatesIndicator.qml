pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick 2.15
import "../components" as C
import QtQuick.Window

Item {
    id: root
    width: 50; height: 40
    property string textValue: "0 󰚰"
    property string statusClass: "ok" // "ok" or "updates"
    property string tooltipText: "System is up to date"
    property bool loading: true

    function refreshUpdates() {
        loading = true
        proc.running = true
    }

    Process {
        id: proc
        command: ["bash","-lc","$HOME/scripts/garuda_updates.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj && obj.text) root.textValue = obj.text
                    if (obj && obj.class) root.statusClass = obj.class
                    if (obj && obj.tooltip) root.tooltipText = obj.tooltip
                } catch (e) {
                    console.error("updates parse error", e)
                }
                root.loading = false
            }
        }
    }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: refreshUpdates() }

    Component.onCompleted: refreshUpdates()

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            run.command = ["bash","-lc","kitty -e bash -lc 'sudo pacman -Syu && paru -Sua --noconfirm; notify-send \"Update complete\"; read -n 1 -s -p \"Press any key to close\"' "]
            run.running = true
        }
    }
    
    Item {
        id: updatesSpinner
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2
        width: 16
        height: 16
        visible: root.loading
        property color strokeColor: C.Theme.updatesAvailable

        Canvas {
            id: updatesSpinnerCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.strokeStyle = updatesSpinner.strokeColor
                ctx.beginPath()
                ctx.arc(width/2, height/2, (width-4)/2, Math.PI * 0.2, Math.PI * 1.7)
                ctx.stroke()
            }
        }

        NumberAnimation on rotation {
            running: root.loading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
            easing.type: Easing.Linear
        }

        onStrokeColorChanged: updatesSpinnerCanvas.requestPaint()
        Component.onCompleted: updatesSpinnerCanvas.requestPaint()
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2
        text: textValue
        color: statusClass === "updates" ? C.Theme.updatesAvailable : C.Theme.updatesNone
        font.pixelSize: 14
        enabled: false  // Make text transparent to mouse events
        visible: !root.loading
    }

    // Tooltip on hover
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: {
            // Convert newlines to HTML line breaks for per-package lines without affecting other modules
            var html = root.tooltipText
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/\n/g, "<br/>")
            // Set tooltip height to 90% of screen height
            var screenHeight = Screen.height
            C.Tooltip.show(root, html, false, { maxHeight: screenHeight })
        }
        onExited: C.Tooltip.hide()
    }
}
