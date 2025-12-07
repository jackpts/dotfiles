import Quickshell
import Quickshell.Io
import Qt.labs.platform
import QtQuick
import "../components" as C

Item {
    id: root
    width: 30; height: 50
    property bool isRecording: false

    // Update the recording state every 1 second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateRecordingState()
    }

    // Process to check recording state
    Process {
        id: stateCheck
        command: ["bash", "-lc", "$HOME/dotfiles/scripts/quickshell_screen_record.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text)
                    root.isRecording = (result.class === "on")
                } catch (e) {
                    console.error("Failed to parse recording state:", e, "Output:", text)
                    root.isRecording = false
                }
            }
        }
    }

    // Process to toggle recording via sway (detached)
    Process { 
        id: toggleProcess
        command: ["bash", "-lc", "$HOME/dotfiles/scripts/quickshell_screen_record.sh --toggle"]
        running: false
        onExited: {
            updateTimer.start()
        }
    }

    // Process to open file manager
    Process { id: fileManager }

    // Detect compositor
    Process {
        id: detect
        command: ["bash","-lc","pgrep -x Hyprland >/dev/null && echo hyprland || (pgrep -x sway >/dev/null && echo sway || echo unknown)"]
        running: true
        stdout: StdioCollector { property string compositor: ""; onStreamFinished: compositor = this.text.trim() }
    }

    // Timer to delay state update after toggle
    Timer {
        id: updateTimer
        interval: 1000
        onTriggered: updateRecordingState()
    }

    // Function to update recording state
    function updateRecordingState() {
        stateCheck.running = true
    }

    // Toggle recording
    function toggleRecording() {
        toggleProcess.running = true
    }

    // Click handling
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                toggleRecording()
            } else if (mouse.button === Qt.RightButton) {
                var videosDir = String(Quickshell.env("HOME")) + "/Videos/Screenrecorder"
                var cmd = ""
                if (detect.stdout.compositor === "hyprland") {
                    cmd = "hyprctl dispatch exec -- nemo '" + videosDir + "' || xdg-open '" + videosDir + "'"
                } else {
                    cmd = "swaymsg exec -- nemo '" + videosDir + "' || xdg-open '" + videosDir + "'"
                }
                fileManager.command = ["bash","-lc", cmd]
                fileManager.running = true
            }
        }
    }

    // Recording indicator
    Text {
        anchors.centerIn: parent
        text: ""
        color: isRecording ? C.Theme.recorderOn : C.Theme.recorderOff
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
    
    // Tooltip
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: C.Tooltip.show(root, isRecording ? "Recording: ON (click to stop)" : "Recording: OFF (click to start)")
        onExited: C.Tooltip.hide()
    }

    // Initial state check
    Component.onCompleted: {
        updateRecordingState()
    }
}
