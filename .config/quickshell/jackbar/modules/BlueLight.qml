import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32; height: 40
    property bool isEnabled: false

    function icon() {
        return isEnabled ? "󰛨" : "󰹏";  // eye / eye-crossed
    }

    // Check blue light state
    Process {
        id: checkProc
        command: ["bash", "-lc", "[ -f ~/.config/bluelight_state ] && cat ~/.config/bluelight_state || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var state = this.text.trim()
                root.isEnabled = (state === "on")
                if (area.containsMouse) {
                    C.Tooltip.show(root, "Blue Light Filter: " + (root.isEnabled ? "ON" : "OFF"))
                }
            }
        }
    }

    // Toggle blue light state
    Process { id: toggleProc }

    function toggleBlueLight() {
        var newState = root.isEnabled ? "off" : "on"
        toggleProc.command = ["bash", "-lc", "echo '" + newState + "' > ~/.config/bluelight_state"]
        toggleProc.running = true
        // Update state immediately for responsive UI
        root.isEnabled = !root.isEnabled
        if (area.containsMouse) {
            C.Tooltip.show(root, "Blue Light Filter: " + (root.isEnabled ? "ON" : "OFF"))
        }
    }

    Timer { 
        interval: 5000; 
        running: true; 
        repeat: true; 
        onTriggered: checkProc.running = true 
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.toggleBlueLight()
        onEntered: C.Tooltip.show(root, "Blue Light Filter: " + (root.isEnabled ? "ON" : "OFF"))
        onExited: C.Tooltip.hide()
    }

    Text {
        anchors.centerIn: parent
        text: root.icon()
        color: root.isEnabled ? "#89b4fa" : "#6c7086"  // blue when on, gray when off
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
}
