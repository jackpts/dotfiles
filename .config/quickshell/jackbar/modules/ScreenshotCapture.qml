import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 30; height: C.Theme.panelHeight

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                run.command = ["sh", "-c", "xdg-open \"${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots\""]
            } else {
                run.command = ["sh", "-c", "WAYLAND_DISPLAY=${WAYLAND_DISPLAY} setsid -f sh -c 'dir=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots; mkdir -p \"$dir\"; filename=\"$dir/$(date +\"%F_%H-%M-%S\").png\"; grim -g \"$(slurp)\" \"$filename\" && wl-copy < \"$filename\"'"]
            }
            run.running = true
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: "󰹑"
        color: C.Theme.screenshotIcon
        font.pixelSize: 20
        // Make text transparent to mouse events so clicks pass through to MouseArea
        enabled: false
    }
}
