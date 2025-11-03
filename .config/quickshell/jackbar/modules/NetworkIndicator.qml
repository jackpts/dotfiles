import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: 40
    property string kind: "disc" // wifi | eth | disc
    property string ssid: ""
    property int signal: 0

    function icon() {
        if (kind === "wifi") return "󰤨";
        if (kind === "eth") return "󰈀";
        return "󰤭";
    }

    Process {
        id: proc
        command: ["bash","-lc",
            "wifi_ssid=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$2==\"wifi\" && $3==\"connected\"{print $4; found=1} END{ if (!found) print \"\" }'); " +
            "if [ -n \"$wifi_ssid\" ]; then kind=wifi; else if nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^ethernet:connected'; then kind=eth; else kind=disc; fi; fi; " +
            "sig=''; if [ \"$kind\" = wifi ]; then sig=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $3}' | head -n1); fi; " +
            "printf '%s|%s|%s\n' \"$kind\" \"$wifi_ssid\" \"$sig\""
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|")
                if (parts.length >= 1) root.kind = parts[0]
                if (parts.length >= 2) root.ssid = parts[1]
                if (parts.length >= 3 && parts[2].length) root.signal = parseInt(parts[2])
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","networkmanager_dmenu || nm-connection-editor"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","kitty -e nmtui"]; run.running = true } }
    }
    
    Text {
        anchors.centerIn: parent
        text: icon()
        color: kind === "disc" ? C.Theme.networkDisconnected : (kind === "wifi" ? C.Theme.networkWifi : C.Theme.networkEthernet)
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
    }
}
