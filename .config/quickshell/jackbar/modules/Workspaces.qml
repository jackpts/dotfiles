import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

Item {
    id: root
    height: 40
    width: items.implicitWidth
    property string compositor: "unknown"
    property var spaces: []

    Row {
        id: items
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: spaces
            delegate: Rectangle {
                radius: 4
                height: 28
                width: 28
                color: modelData.focused ? C.Theme.wsActiveBg : C.Theme.wsBg
                border.color: modelData.urgent ? C.Theme.red : C.Theme.wsBorder
                border.width: modelData.focused ? 2 : 1
                Text {
                    anchors.centerIn: parent
                    text: modelData.num
                    color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.compositor === "sway") {
                            run.command = ["bash","-lc","swaymsg workspace number " + modelData.num]
                            run.running = true
                        } else if (root.compositor === "niri") {
                            run.command = ["bash","-lc","niri msg action focus-workspace " + modelData.num]
                            run.running = true
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onWheel: function(wheel) {
            if (root.compositor === "sway") {
                run.command = ["bash","-lc", wheel.angleDelta.y > 0 ? "swaymsg workspace next" : "swaymsg workspace prev"]
                run.running = true
            } else if (root.compositor === "niri") {
                run.command = ["bash","-lc", wheel.angleDelta.y > 0 ? "niri msg action focus-workspace-up" : "niri msg action focus-workspace-down"]
                run.running = true
            }
        }
    }

    Process { id: run }

    Process {
        id: detect
        command: ["bash","-lc","pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown)"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.compositor = this.text.trim() }
    }

    Process {
        id: swayWs
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text)
                    var mapped = []
                    for (var i=0;i<arr.length;i++) mapped.push({ num: arr[i].num, name: arr[i].name, focused: !!arr[i].focused, urgent: !!arr[i].urgent })
                    mapped.sort(function(a,b){ return a.num - b.num })
                    root.spaces = mapped
                } catch (e) {}
            }
        }
    }

    Process {
        id: niriWs
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text
                var m = t.match(/\*\s*([0-9]+)/)
                var focused = m ? parseInt(m[1]) : -1
                var out = []
                for (var n=1;n<=9;n++) out.push({ num: n, name: ""+n, focused: n===focused, urgent: false })
                root.spaces = out
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (root.compositor === "sway") {
                swayWs.command = ["bash","-lc","swaymsg -r -t get_workspaces"]; swayWs.running = true
            } else if (root.compositor === "niri") {
                niriWs.command = ["bash","-lc","niri msg workspaces"]; niriWs.running = true
            }
        }
    }
}
