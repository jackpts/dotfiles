import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

Item {
    id: root
    height: 50
    width: items.implicitWidth
    property string compositor: "unknown"
    property var spaces: []
    property int activeWsId: -1

    function getWorkspaceIcon(ws) {
        if (ws.focused) return "󰮯"  // active: filled circle
        if (ws.windows > 0) return "◉"  // default: fisheye
        // return "○"  // empty: circle
        return ""  // empty: circle
    }

    Row {
        id: items
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: spaces
            delegate: Rectangle {
                radius: 2
                height: 38
                width: 38
                color: modelData.focused ? C.Theme.wsActiveBg : C.Theme.wsBg
                border.color: modelData.focused ? "#8b7ec8" : (modelData.urgent ? C.Theme.red : C.Theme.wsBorder)
                border.width: modelData.focused ? 2 : 1
                Text {
                    anchors.centerIn: parent
                    text: root.getWorkspaceIcon(modelData)
                    color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.compositor === "hyprland") {
                            run.command = ["bash","-lc","hyprctl dispatch workspace " + modelData.num]
                            run.running = true
                        } else if (root.compositor === "sway") {
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
        acceptedButtons: Qt.NoButton  // Don't accept clicks, only wheel events
        propagateComposedEvents: true  // Let clicks pass through to workspace buttons
        onWheel: function(wheel) {
            if (root.compositor === "hyprland") {
                run.command = ["bash","-lc", wheel.angleDelta.y > 0 ? "hyprctl dispatch workspace m+1" : "hyprctl dispatch workspace m-1"]
                run.running = true
            } else if (root.compositor === "sway") {
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
        command: ["bash","-lc","pgrep -x Hyprland >/dev/null && echo hyprland || (pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown))"]
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
                    for (var i=0;i<arr.length;i++) mapped.push({ num: arr[i].num, name: arr[i].name, focused: !!arr[i].focused, urgent: !!arr[i].urgent, windows: arr[i].windows || 0 })
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
                for (var n=1;n<=9;n++) out.push({ num: n, name: ""+n, focused: n===focused, urgent: false, windows: 0 })
                root.spaces = out
            }
        }
    }

    Process {
        id: hyprWs
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text)
                    var workspaceData = {}
                    var maxWs = 0
                    
                    // Build a map of workspace data
                    for (var i=0;i<arr.length;i++) {
                        // Skip special workspaces (negative IDs)
                        if (arr[i].id < 0) continue
                        workspaceData[arr[i].id] = {
                            focused: arr[i].id === root.activeWsId,
                            urgent: false,
                            windows: arr[i].windows || 0
                        }
                        if (arr[i].id > maxWs) maxWs = arr[i].id
                    }
                    
                    // Show workspaces 1-5, or up to maxWs if higher
                    var mapped = []
                    var wsLimit = Math.max(5, maxWs)
                    for (var n=1; n<=wsLimit; n++) {
                        var ws = workspaceData[n] || { focused: false, urgent: false, windows: 0 }
                        mapped.push({ 
                            num: n, 
                            name: ""+n, 
                            focused: ws.focused,
                            urgent: ws.urgent,
                            windows: ws.windows
                        })
                    }
                    root.spaces = mapped
                } catch (e) {
                    console.error("Hyprland workspace parse error:", e)
                }
            }
        }
    }

    // Hyprland: get currently active workspace id
    Process {
        id: hyprActive
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    root.activeWsId = obj.id
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (root.compositor === "hyprland") {
                hyprActive.command = ["bash","-lc","hyprctl activeworkspace -j"]; hyprActive.running = true
                hyprWs.command = ["bash","-lc","hyprctl workspaces -j"]; hyprWs.running = true
            } else if (root.compositor === "sway") {
                swayWs.command = ["bash","-lc","swaymsg -r -t get_workspaces"]; swayWs.running = true
            } else if (root.compositor === "niri") {
                niriWs.command = ["bash","-lc","niri msg workspaces"]; niriWs.running = true
            }
        }
    }
}
