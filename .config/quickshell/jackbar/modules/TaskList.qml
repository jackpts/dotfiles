import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

Item {
    id: root
    height: 40
    width: row.implicitWidth
    property string compositor: "unknown"
    property var wins: [] // [{id, app, title, focused, urgent}]

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: wins
            delegate: Rectangle {
                radius: 4
                height: 28
                color: modelData.focused ? C.Theme.wsActiveBg : C.Theme.wsBg
                border.color: modelData.urgent ? C.Theme.red : C.Theme.wsBorder
                border.width: modelData.focused ? 2 : 1
                width: Math.min(180, Math.max(44, label.implicitWidth + 16))
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        id: icon
                        text: "" // placeholder icon
                        visible: false
                    }
                    Text {
                        id: label
                        text: modelData.app ? modelData.app : (modelData.title || "?")
                        color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (root.compositor === "sway") {
                            run.command = ["bash","-lc", "swaymsg '[con_id=" + modelData.id + "] focus'"]
                            run.running = true
                        }
                    }
                    onPressed: function(mouse) { if (mouse.button === Qt.RightButton && root.compositor === "sway") {
                        run.command = ["bash","-lc", "swaymsg '[con_id=" + modelData.id + "] kill'"]
                        run.running = true
                    } }
                }
            }
        }
    }

    Process { id: run }

    // Detect compositor
    Process {
        id: detect
        command: ["bash","-lc","pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown)"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.compositor = this.text.trim() }
    }

    // Sway: poll tree and extract windows
    Process {
        id: swayTree
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split(/\n/)
                var list = []
                for (var i=0;i<lines.length;i++) {
                    var line = lines[i]
                    if (!line.length) continue
                    try {
                        var o = JSON.parse(line)
                        list.push({ id: o.id, app: o.app, title: o.title, focused: !!o.focused, urgent: !!o.urgent })
                    } catch (e) {}
                }
                root.wins = list
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (root.compositor === "sway") {
                swayTree.command = ["bash","-lc",
                    "swaymsg -r -t get_tree | jq -c \".. | objects | select(.type? == 'con' or .type? == 'floating_con') | select(.app_id? or .window_properties?.class?) | {id, app: (.app_id // .window_properties.class), title: .name, focused: (.focused // false), urgent: (.urgent // false)}\""
                ];
                swayTree.running = true
            }
        }
    }
}
