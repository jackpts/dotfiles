import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    
    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        // Left click - Launch app menu
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                run.command = ["bash", "-lc", "$HOME/scripts/run_launcher.sh"]
                run.running = true
            }
            // Right click - Show power menu
            else if (mouse.button === Qt.RightButton) {
                run.command = ["bash", "-lc", "$HOME/scripts/powermenu.sh"]
                run.running = true
            }
            // Middle click - Reload sway
            else if (mouse.button === Qt.MiddleButton) {
                run.command = ["bash", "-lc", "swaymsg reload"]
                run.running = true
            }
        }
    }
    
    // Garuda logo/icon
    Text {
        anchors.centerIn: parent
        text: ""  // Same icon as in Waybar
        color: C.Theme.text
        font.pixelSize: 20
        enabled: false  // Make text transparent to mouse events
    }
    
    // Tooltip
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: C.Tooltip.show(root, "Garuda Menu/Power")
        onExited: C.Tooltip.hide()
    }
}
