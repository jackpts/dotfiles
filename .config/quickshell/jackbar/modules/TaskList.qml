import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

Item {
    id: root
    height: 50
    width: Math.max(20, row.implicitWidth)
    property string compositor: "unknown"
    property var wins: [] // [{id, app, title, focused, urgent}]

    function collectWindows(node, list) {
        if (!node) return
        var isWin = (node.type === 'con' || node.type === 'floating_con') && (node.app_id || (node.window_properties && node.window_properties.class))
        if (isWin) {
            list.push({
                id: node.id,
                app: node.app_id || (node.window_properties ? node.window_properties.class : undefined),
                title: node.name,
                focused: !!node.focused,
                urgent: !!node.urgent
            })
        }
        var children = []
        if (node.nodes && node.nodes.length) children = children.concat(node.nodes)
        if (node.floating_nodes && node.floating_nodes.length) children = children.concat(node.floating_nodes)
        for (var i = 0; i < children.length; i++) {
            collectWindows(children[i], list)
        }
    }

    // Get the active window address for more reliable focus detection
    property string activeWindowAddress: ""
    function getFocusedWindow(callback) {
        if (root.compositor === "hyprland" && callback) {
            callback(root.activeWindowAddress)
        } else if (callback) {
            callback("")
        }
    }

	function normalizeAppId(appId) {
		if (!appId || appId.indexOf('.') === -1)
			return appId || ""
		var parts = appId.split('.')
		// remove empty and generic trailing tokens
		var generics = { "desktop": true, "app": true, "application": true }
		var filtered = []
		for (var i = 0; i < parts.length; i++) {
			var p = parts[i].trim()
			if (!p.length) continue
			filtered.push(p)
		}
		for (var j = filtered.length - 1; j >= 0; j--) {
			var seg = filtered[j]
			var key = seg.toLowerCase()
			if (!generics[key]) {
				return key
			}
		}
		// fallback to last segment
		return filtered.length ? filtered[filtered.length - 1].toLowerCase() : (appId.toLowerCase())
	}

    function shortLabel(app, title) {
		var base = app && app.length ? ((app.indexOf('.') !== -1) ? normalizeAppId(app) : app) : (title || "?")
        // Trim common separators to get the leading part (e.g., "Page - Firefox")
        var seps = [" — ", " - ", " | ", ": "]
        for (var i = 0; i < seps.length; i++) {
            var idx = base.indexOf(seps[i])
            if (idx > 0) { base = base.substring(0, idx); break }
        }
        base = base.replace(/\s+/g, ' ').trim()
        if (base.length > 24) base = base.substring(0, 21) + "…"
        return base
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        // Placeholder so the module is visible when there are no windows
        Rectangle {
            visible: wins.length === 0
            radius: 2
            height: 38
            width: 30
            color: C.Theme.wsBg
            border.color: C.Theme.wsBorder
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: "–"
                color: C.Theme.wsText
                font.pixelSize: 14
            }
        }
        Repeater {
            model: wins
            delegate: Rectangle {
                radius: 1
                height: 35
                // color: modelData.focused ? C.Theme.wsActiveBg : C.Theme.wsBg
                color: C.Theme.wsBg
                border.color: modelData.focused ? C.Theme.darkRed : (modelData.urgent ? C.Theme.red : C.Theme.wsBorder)
                border.width: modelData.focused ? 1 : 1  // for future use
                width: Math.min(180, Math.max(44, label.implicitWidth + 16))
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        id: label
                        text: root.shortLabel(modelData.app, modelData.title)
                        color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                        font.pixelSize: 16
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (root.compositor === "hyprland") {
                            run.command = ["bash","-lc", "hyprctl dispatch focuswindow address:0x" + modelData.id.toString(16)]
                            run.running = true
                        } else if (root.compositor === "sway") {
                            run.command = ["bash","-lc", "swaymsg '[con_id=" + modelData.id + "] focus'"]
                            run.running = true
                        }
                    }
                    onPressed: function(mouse) { 
                        if (mouse.button === Qt.RightButton) {
                            if (root.compositor === "hyprland") {
                                run.command = ["bash","-lc", "hyprctl dispatch closewindow address:0x" + modelData.id.toString(16)]
                                run.running = true
                            } else if (root.compositor === "sway") {
                                run.command = ["bash","-lc", "swaymsg '[con_id=" + modelData.id + "] kill'"]
                                run.running = true
                            }
                        }
                    }
                    hoverEnabled: true
                    onEntered: C.Tooltip.show(root, modelData.title || modelData.app || "?")
                    onExited: C.Tooltip.hide()
                }
            }
        }
    }

    Process { id: run }

    // Detect compositor
    Process {
        id: detect
        command: ["bash","-lc","pgrep -x Hyprland >/dev/null && echo hyprland || (pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown))"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.compositor = this.text.trim() }
    }

    // Sway: poll tree and extract windows
    Process {
        id: swayTree
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var tree = JSON.parse(this.text)
                    var list = []
                    root.collectWindows(tree, list)
                    root.wins = list
                } catch (e) {
                    root.wins = []
                }
            }
        }
    }

    // Hyprland: poll active window
    Process {
        id: hyprActiveWindow
        stdout: StdioCollector {
            onStreamFinished: {
                // Store the active window info
                try {
                    var activeObj = JSON.parse(this.text)
                    root.activeWindowAddress = activeObj.address || ""
                } catch (e) {
                    console.error("Failed to parse active window:", e)
                    root.activeWindowAddress = ""
                }
            }
        }
    }

    // Hyprland: poll clients list
    Process {
        id: hyprClients
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text)
                    var list = []
                    // Get active window address
                    root.getFocusedWindow(function(activeWindowAddress) {
                        for (var i = 0; i < arr.length; i++) {
                            var client = arr[i]
                            // Compare addresses for accurate focus detection
                            var isFocused = client.address === activeWindowAddress
                            // LIMITATION: Hyprland doesn't expose urgent/attention state in hyprctl output
                            // Unlike Sway which includes node.urgent in get_tree, Hyprland's clients -j
                            // doesn't provide this information even when apps request attention.
                            // 
                            // Potential workarounds:
                            // 1. Listen to Hyprland event socket for urgent events (requires socat/async)
                            // 2. Use windowrule to set custom tags when urgent is triggered
                            // 3. Parse window titles for notification counts (app-specific, unreliable)
                            //
                            // For now, urgent detection is disabled for Hyprland.
                            var isUrgent = false;
                            
                            list.push({
                                id: parseInt(client.address, 16),  // Convert hex address to int
                                app: client.class || client.initialClass,
                                title: client.title,
                                focused: isFocused,
                                urgent: isUrgent
                            })
                        }
                        root.wins = list
                    })
                } catch (e) {
                    console.error("Hyprland clients parse error:", e)
                    root.wins = []
                }
            }
        }
    }

    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            if (root.compositor === "hyprland") {
                hyprActiveWindow.command = ["bash","-lc", "hyprctl activewindow -j"];
                hyprActiveWindow.running = true
                // Get clients list after a small delay to ensure active window is available
                updateClientsTimer.start()
            } else if (root.compositor === "sway") {
                swayTree.command = ["bash","-lc", "swaymsg -r -t get_tree"];
                swayTree.running = true
            }
        }
    }

    Timer {
        id: updateClientsTimer
        interval: 50
        onTriggered: {
            if (root.compositor === "hyprland") {
                hyprClients.command = ["bash","-lc", "hyprctl clients -j"];
                hyprClients.running = true
            }
        }
    }
}
