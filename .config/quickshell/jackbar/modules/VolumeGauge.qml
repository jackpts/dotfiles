import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property int volume: 0
    property bool muted: false

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        color: muted ? C.Theme.volumeMuted : C.Theme.volumeActive
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
    Timer { interval: 1000; running: true; repeat: true; onTriggered: { update.command = ["bash","-lc","wpctl get-volume @DEFAULT_AUDIO_SINK@ "]; update.running = true } }

    Process { id: run }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","pavucontrol"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]; run.running = true } }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) { run.command = ["bash","-lc","wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"] } else { run.command = ["bash","-lc","wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"] }
            run.running = true
        }
    }

    Connections {
        target: gauge
        function onHoveredChanged() {
            if (gauge.hovered) {
                var txt = "Volume: " + volume + "%" + (muted ? " (muted)" : "")
                C.Tooltip.show(gauge, txt)
            } else {
                C.Tooltip.hide()
            }
        }
    }
}
