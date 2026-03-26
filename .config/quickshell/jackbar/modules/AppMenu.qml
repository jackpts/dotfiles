import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 30
    height: 40

    // Dedicated processes
    Process {
        id: launcherProcess
    }
    Process {
        id: powerMenuProcess
    }
    Process {
        id: reloadProcess
    }
    Process {
        id: killProcess // New: For force-killing detached processes via shell command
    }

    // Visual feedback
    property color activeColor: "red"
    property color inactiveColor: C.Theme.appMenu
    function getIconColor() {
        if (launcherProcess.running || powerMenuProcess.running) {
            return activeColor;
        }
        return inactiveColor;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function (mouse) {
            const isLauncherOpen = launcherProcess.running;
            const isPowerMenuOpen = powerMenuProcess.running;

            // --- Closing Logic ---
            if (isLauncherOpen || isPowerMenuOpen) {
                // 1. Force kill any running processes tracked by QML (for graceful exit if possible)
                if (isLauncherOpen) {
                    launcherProcess.running = false;
                }
                if (isPowerMenuOpen) {
                    powerMenuProcess.running = false;
                }

                // 2. Force kill detached rofi processes via shell command (SIGKILL)
                if (isLauncherOpen) {
                    // Kill launcher's rofi instance (assuming launcher script is in $HOME/scripts)
                    killProcess.command = ["pkill", "-9", "-f", "$HOME/scripts/run_launcher.sh"];
                    killProcess.running = true;
                }
                if (isPowerMenuOpen) {
                    // Kill power menu's rofi instance (targeting the unique message argument)
                    killProcess.command = ["pkill", "-9", "-f", "rofi -dmenu"];
                    killProcess.running = true;
                }

                // 3. Handle Middle Click (Reload Sway)
                if (mouse.button === Qt.MiddleButton) {
                    reloadProcess.command = ["bash", "-lc", "swaymsg reload"];
                    reloadProcess.running = true;
                }
                return; // Stop execution after closing
            }

            // --- Launch Logic (only runs if nothing was open initially) ---
            if (mouse.button === Qt.LeftButton) {
                launcherProcess.command = ["bash", "-lc", "$HOME/scripts/run_launcher.sh"];
                launcherProcess.running = true;
            } else if (mouse.button === Qt.RightButton) {
                powerMenuProcess.command = ["bash", "-lc", "$HOME/scripts/powermenu.sh"];
                powerMenuProcess.running = true;
            }
        }
    }

    // Garuda logo/icon
    Text {
        anchors.centerIn: parent
        text: "󰣇"
        color: root.getIconColor()
        font.pixelSize: 16
        enabled: false  // Make text transparent to mouse events
    }

    // Tooltip
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: C.Tooltip.show(root, "Menu/Power")
        onExited: C.Tooltip.hide()
    }
}
