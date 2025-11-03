import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property bool on: false

    Process {
        id: poll
        command: ["bash","-lc","$HOME/scripts/screen_record.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { var obj = JSON.parse(this.text); root.on = (obj.class === "on") } catch (e) { root.on = false }
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: poll.running = true }

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","$HOME/scripts/screen_record.sh --toggle"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","nemo $(xdg-user-dir VIDEOS)/Screenrecorder"]; run.running = true } }
    }
    
    Text {
        anchors.centerIn: parent
        text: ""
        color: on ? C.Theme.recorderOn : C.Theme.recorderOff
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
}
