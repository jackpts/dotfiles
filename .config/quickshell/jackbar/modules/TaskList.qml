import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components" as C

Item {
    id: root
    height: C.Theme.panelHeight
    width: Math.max(20, calculateTotalWidth())
    property string compositor: "unknown"
    property var wins: [] // [{id, app, title, focused, urgent, workspace}]
    property int minWorkspace: 1
    property int panelMaxWorkspace: 4
    property int maxMoveWorkspace: panelMaxWorkspace + 1
    property bool menuOpen: false
    property var contextWindow: null
    property var moveTargets: []
    property int menuWidth: C.Theme.scale(200)
    property int menuX: 0
    property int menuY: 0

    function closeContextMenu() {
        menuOpen = false;
        contextWindow = null;
    }

    function updateMoveTargets() {
        if (!contextWindow) {
            moveTargets = [];
            return;
        }
        var targets = [];
        for (var n = minWorkspace; n <= maxMoveWorkspace; n++) {
            if (Number(n) !== Number(contextWindow.workspace))
                targets.push(n);
        }
        moveTargets = targets;
    }

    function openContextMenu(win, anchor) {
        C.Tooltip.hide();
        contextWindow = win;
        var pt = anchor.mapToGlobal(0, anchor.height + C.Theme.scale(6));
        menuX = isFinite(pt.x) ? Math.max(0, Math.round(pt.x)) : 8;
        menuY = isFinite(pt.y) ? Math.max(0, Math.round(pt.y)) : C.Theme.panelHeight + 4;
        updateMoveTargets();
        menuOpen = true;
    }

    function moveToWorkspace(num) {
        if (!contextWindow || compositor !== "sway")
            return;
        run.command = ["bash", "-lc", "swaymsg '[con_id=" + contextWindow.id + "] move container to workspace number " + num + "'"];
        run.running = true;
    }

    function killContextWindow() {
        if (!contextWindow || compositor !== "sway")
            return;
        run.command = ["bash", "-lc", "swaymsg '[con_id=" + contextWindow.id + "] kill'"];
        run.running = true;
    }

    function collectWindows(node, list, workspaceNum) {
        if (!node)
            return;
        if (node.type === "workspace")
            workspaceNum = node.num;
        var isWin = (node.type === 'con' || node.type === 'floating_con') && (node.app_id || (node.window_properties && node.window_properties.class));
        if (isWin) {
            var appId = node.app_id || (node.window_properties ? node.window_properties.class : '');
            list.push({
                id: node.id,
                app: appId,
                title: node.name,
                focused: !!node.focused,
                urgent: !!node.urgent,
                workspace: workspaceNum
            });
        }
        var children = [];
        if (node.nodes && node.nodes.length)
            children = children.concat(node.nodes);
        if (node.floating_nodes && node.floating_nodes.length)
            children = children.concat(node.floating_nodes);
        for (var i = 0; i < children.length; i++)
            collectWindows(children[i], list, workspaceNum);
    }

    function normalizeAppId(appId) {
        if (!appId || appId.indexOf('.') === -1)
            return appId || "";
        var parts = appId.split('.');
        var generics = {
            "desktop": true,
            "app": true,
            "application": true
        };
        var filtered = [];
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim();
            if (!p.length)
                continue;
            filtered.push(p);
        }
        for (var j = filtered.length - 1; j >= 0; j--) {
            var seg = filtered[j];
            var key = seg.toLowerCase();
            if (!generics[key])
                return key;
        }
        return filtered.length ? filtered[filtered.length - 1].toLowerCase() : (appId.toLowerCase());
    }

    function stripVendorWords(name) {
        if (!name)
            return "";
        var tokens = name.split(/[-\s_]+/);
        var filtered = [];
        var vendorWords = {
            "google": true,
            "libreoffice": true
        };
        for (var i = 0; i < tokens.length; i++) {
            var t = tokens[i].trim();
            if (!t.length)
                continue;
            if (vendorWords[t.toLowerCase()])
                continue;
            filtered.push(t);
        }
        if (!filtered.length)
            return name;
        return filtered.join(" ");
    }

    function shortLabel(app, title) {
        var base = app && app.length ? ((app.indexOf('.') !== -1) ? normalizeAppId(app) : app) : (title || "?");
        base = stripVendorWords(base);
        if (normalizeAppId(app).indexOf("transmission") === 0)
            base = "transmission";
        var seps = [" — ", " - ", " | ", ": "];
        for (var i = 0; i < seps.length; i++) {
            var idx = base.indexOf(seps[i]);
            if (idx > 0) {
                base = base.substring(0, idx);
                break;
            }
        }
        base = base.replace(/\s+/g, ' ').trim();
        if (base.length > 24)
            base = base.substring(0, 21) + "…";
        return base;
    }

    function calculateTotalWidth() {
        if (wins.length === 0)
            return 20;
        var total = 0;
        for (var i = 0; i < wins.length; i++) {
            var label = shortLabel(wins[i].app, wins[i].title);
            var labelWidth = Math.min(label.length * 8 + 10, 100);
            var canvasWidth = labelWidth + 2 + Math.tan(30 * Math.PI / 180) * 28;
            total += canvasWidth;
        }
        return total;
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: -7
        Canvas {
            visible: wins.length === 0
            height: C.Theme.scale(28)
            width: 20
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var angleRad = 30 * Math.PI / 180;
                var offset = Math.tan(angleRad) * height / 2;

                ctx.beginPath();
                ctx.moveTo(offset, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width - offset, height);
                ctx.lineTo(0, height);
                ctx.closePath();

                ctx.fillStyle = C.Theme.wsBg;
                ctx.fill();
                ctx.strokeStyle = C.Theme.wsBorder;
                ctx.lineWidth = 1;
                ctx.stroke();
            }
            Text {
                anchors.centerIn: parent
                text: "–"
                color: C.Theme.wsText
                font.pixelSize: C.Theme.fontSm
            }
        }
        Repeater {
            model: wins
            delegate: Item {
                id: taskTab
                height: C.Theme.scale(28)
                width: label.implicitWidth + 2 + Math.tan(30 * Math.PI / 180) * height
                property var win: modelData

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var w = taskTab.win;
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var angleRad = 30 * Math.PI / 180;
                        var offset = Math.tan(angleRad) * height / 2;

                        ctx.beginPath();
                        ctx.moveTo(offset, 0);
                        ctx.lineTo(width, 0);
                        ctx.lineTo(width - offset, height);
                        ctx.lineTo(0, height);
                        ctx.closePath();

                        ctx.fillStyle = w.focused ? C.Theme.wsActiveBg : C.Theme.wsBg;
                        ctx.fill();
                        ctx.strokeStyle = w.urgent ? C.Theme.red : C.Theme.wsBorder;
                        ctx.lineWidth = w.focused ? 2 : 1;
                        ctx.stroke();
                    }
                }
                Row {
                    anchors.centerIn: parent
                    anchors.left: parent.left
                    anchors.leftMargin: 1
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    spacing: 0
                    Text {
                        id: label
                        text: root.shortLabel(win.app, win.title)
                        color: win.focused ? C.Theme.wsTextActive : C.Theme.wsText
                        font.pixelSize: C.Theme.fontSm
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function (mouse) {
                        if (root.compositor !== "sway")
                            return;
                        if (mouse.button === Qt.LeftButton) {
                            root.closeContextMenu();
                            run.command = ["bash", "-lc", "swaymsg '[con_id=" + win.id + "] focus'"];
                            run.running = true;
                        } else if (mouse.button === Qt.RightButton) {
                            root.openContextMenu(win, taskTab);
                        }
                    }
                    hoverEnabled: true
                    onEntered: C.Tooltip.show(root, win.title || win.app || "?")
                    onExited: C.Tooltip.hide()
                }
            }
        }
    }

    PanelWindow {
        id: contextMenuLayer
        visible: root.menuOpen
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        exclusiveZone: 0
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-taskmenu"

        onVisibleChanged: {
            if (visible)
                contextMenuLayer.forceActiveFocus();
        }

        Keys.onEscapePressed: root.closeContextMenu()

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: root.closeContextMenu()
        }

        Rectangle {
            id: menuBox
            z: 1
            x: root.menuX
            y: root.menuY
            width: root.menuWidth
            implicitHeight: menuColumn.implicitHeight + C.Theme.scale(16)
            height: implicitHeight
            color: "#1e1e2e"
            border.color: C.Theme.appMenu
            border.width: 1
            radius: 0

            Column {
                id: menuColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: C.Theme.scale(8)
                spacing: C.Theme.scale(2)
                width: menuBox.width - C.Theme.scale(16)

                Text {
                    width: menuColumn.width
                    leftPadding: C.Theme.scale(4)
                    text: root.contextWindow ? root.shortLabel(root.contextWindow.app, root.contextWindow.title) : ""
                    color: C.Theme.wsTextActive
                    font.pixelSize: C.Theme.fontSm
                    elide: Text.ElideRight
                }

                Text {
                    width: menuColumn.width
                    leftPadding: C.Theme.scale(4)
                    text: root.contextWindow && root.contextWindow.workspace != null
                        ? "Workspace " + root.contextWindow.workspace
                        : ""
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                }

                Rectangle {
                    width: menuColumn.width
                    height: 1
                    color: "#313244"
                }

                Text {
                    width: menuColumn.width
                    leftPadding: C.Theme.scale(4)
                    topPadding: C.Theme.scale(2)
                    text: "Move to workspace"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                }

                Repeater {
                    model: root.moveTargets
                    delegate: Rectangle {
                        width: menuColumn.width
                        height: C.Theme.scale(28)
                        color: moveMouse.containsMouse ? "#313244" : "transparent"
                        radius: 0

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: C.Theme.scale(8)
                            text: "Workspace " + modelData
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                        }

                        MouseArea {
                            id: moveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.moveToWorkspace(modelData);
                                root.closeContextMenu();
                            }
                        }
                    }
                }

                Rectangle {
                    width: menuColumn.width
                    height: 1
                    color: "#313244"
                }

                Rectangle {
                    width: menuColumn.width
                    height: C.Theme.scale(28)
                    color: killMouse.containsMouse ? "#452028" : "transparent"
                    radius: 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: C.Theme.scale(8)
                        text: "Close window"
                        color: C.Theme.red
                        font.pixelSize: C.Theme.fontSm
                    }

                    MouseArea {
                        id: killMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.killContextWindow();
                            root.closeContextMenu();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: run
    }

    Process {
        id: detect
        command: ["bash", "-lc", "pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.compositor = this.text.trim()
        }
    }

    Process {
        id: swayTree
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var tree = JSON.parse(this.text);
                    var list = [];
                    root.collectWindows(tree, list, null);
                    root.wins = list;
                } catch (e) {
                    root.wins = [];
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.compositor === "sway") {
                swayTree.command = ["bash", "-lc", "swaymsg -r -t get_tree"];
                swayTree.running = true;
            }
        }
    }
}
