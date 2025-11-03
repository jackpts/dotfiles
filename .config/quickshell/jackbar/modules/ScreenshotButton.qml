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
        onClicked: {
            run.command = ["bash","-lc",
                "dir=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots; mkdir -p \"$dir\"; file=\"$dir/$(date +'%F_%H-%M-%S').png\"; grim -g \"$(slurp)\" \"$file\" && wl-copy < \"$file\" && notify-send 'Screenshot' 'Saved and copied'"
            ];
            run.running = true
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: "󰹑"
        color: C.Theme.screenshotIcon
        font.pixelSize: 18
        // Make text transparent to mouse events so clicks pass through to MouseArea
        enabled: false
    }
}
