/*------------------
--- Redshift.qml ---
------------------*/

import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32
    height: 40
    
    property bool enabled: false
    property string startTime: "19:00"
    property string endTime: "07:00"
    
    function icon() {
        return enabled ? "󰖔" : "󰖕"  // night-light icons
    }
    
    // Check redshift/gammastep state
    Process {
        id: checkProc
        command: ["bash", "-lc", "pgrep -x 'redshift|gammastep' > /dev/null && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var state = this.text.trim()
                root.enabled = (state === "on")
                if (area.containsMouse) {
                    C.Tooltip.show(root, "Night Light: " + (root.enabled ? "ON" : "OFF"))
                }
            }
        }
    }
    
    Process { id: toggleProc }
    
    function toggleRedshift() {
        if (root.enabled) {
            // Kill redshift/gammastep
            toggleProc.command = ["bash", "-lc", "pkill -x 'redshift|gammastep'"]
        } else {
            // Start gammastep (more modern alternative to redshift)
            toggleProc.command = ["bash", "-lc", "gammastep -l 0:0 -t 5700:3400 &"]
        }
        toggleProc.running = true
        // Update state immediately for responsive UI
        root.enabled = !root.enabled
        if (area.containsMouse) {
            C.Tooltip.show(root, "Night Light: " + (root.enabled ? "ON" : "OFF"))
        }
    }
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: checkProc.running = true
    }
    
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.toggleRedshift()
        onEntered: C.Tooltip.show(root, "Night Light: " + (root.enabled ? "ON" : "OFF"))
        onExited: C.Tooltip.hide()
    }
    
    Text {
        anchors.centerIn: parent
        text: root.icon()
        color: root.enabled ? "#f9e2af" : "#6c7086"  // yellow when on, gray when off
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
