import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property int volume: 0
    property bool muted: false
    property int inputVolume: 0
    property string sinkName: "Output"
    property string sourceName: "Input"

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        color: muted ? C.Theme.volumeMuted : C.Theme.yellow  //  C.Theme.volumeActive
        trackColor: C.Theme.track
        value: muted ? 0 : volume/100
        label: muted ? "M" : (volume + "%")
    }

    Process { id: update; stdout: StdioCollector {
        onStreamFinished: {
            var out = this.text.trim()
            var m = out.match(/([0-9.]+)/)
            root.volume = m ? Math.round(parseFloat(m[1]) * 100) : 0
            root.muted = out.indexOf("MUTED") !== -1
        }
    }}
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            update.command = ["bash","-lc","wpctl get-volume @DEFAULT_AUDIO_SINK@ "]
            update.running = true
            updateInput.command = ["bash","-lc","wpctl get-volume @DEFAULT_AUDIO_SOURCE@ "]
            updateInput.running = true
        }
    }

    Process { id: updateInput; stdout: StdioCollector {
        onStreamFinished: {
            var out = this.text.trim()
            var m = out.match(/([0-9.]+)/)
            root.inputVolume = m ? Math.round(parseFloat(m[1]) * 100) : 0
        }
    }}

    // Refresh default device names periodically
    Process { id: names; stdout: StdioCollector {
        onStreamFinished: {
            var lines = this.text.split(/\n/) 
            if (lines.length >= 1 && lines[0].length) {
                // Prefer pretty name in parentheses if present
                var m1 = lines[0].match(/\(([^)]+)\)/)
                root.sinkName = m1 ? m1[1] : lines[0].trim()
            }
            if (lines.length >= 2 && lines[1].length) {
                var m2 = lines[1].match(/\(([^)]+)\)/)
                root.sourceName = m2 ? m2[1] : lines[1].trim()
            }
        }
    }}
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            names.command = ["bash","-lc", "wpctl status | awk -F': ' '/Default Sink:/ {print $2} /Default Source:/ {print $2}'"]
            names.running = true
        }
    }

    Process { id: run }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","pavucontrol"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]; run.running = true } }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) { run.command = ["bash","-lc","wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"] } else { run.command = ["bash","-lc","wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"] }
            run.running = true
        }
        onEntered: {
            var line1 = root.sinkName + ": " + volume + "%" + (muted ? " (muted)" : "")
            var line2 = root.sourceName + ": " + inputVolume + "%"
            C.Tooltip.show(root, line1 + "<br>" + line2)
        }
        onExited: C.Tooltip.hide()
    }

    // Tooltip now handled by the outer MouseArea hover events
}
