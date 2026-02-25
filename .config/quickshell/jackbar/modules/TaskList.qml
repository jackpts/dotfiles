import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

Item {
    id: root
    height: 40
    width: Math.max(20, calculateTotalWidth())
    property string compositor: "unknown"
    property var wins: [] // [{id, app, title, focused, urgent}]

    function collectWindows(node, list) {
        if (!node)
            return;
        var isWin = (node.type === 'con' || node.type === 'floating_con') && (node.app_id || (node.window_properties && node.window_properties.class));
        if (isWin) {
            var appId = node.app_id || (node.window_properties ? node.window_properties.class : '');
            // Skip zen-browser windows entirely
            // if (appId && (appId.includes('zen-browser') || appId.includes('zen'))) {
            // return
            // }
            list.push({
                id: node.id,
                app: appId,
                title: node.name,
                focused: !!node.focused,
                urgent: !!node.urgent
            });
        }
        var children = [];
        if (node.nodes && node.nodes.length)
            children = children.concat(node.nodes);
        if (node.floating_nodes && node.floating_nodes.length)
            children = children.concat(node.floating_nodes);
        for (var i = 0; i < children.length; i++) {
            collectWindows(children[i], list);
        }
    }

    function normalizeAppId(appId) {
        if (!appId || appId.indexOf('.') === -1)
            return appId || "";
        var parts = appId.split('.');
        // remove empty and generic trailing tokens
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
            if (!generics[key]) {
                return key;
            }
        }
        // fallback to last segment
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
        // Trim common separators to get the leading part (e.g., "Page - Firefox")
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
            return 20; // placeholder width
        var total = 0;
        for (var i = 0; i < wins.length; i++) {
            var label = shortLabel(wins[i].app, wins[i].title);
            var labelWidth = Math.min(label.length * 8 + 10, 100); // estimate text width, max 100px
            var canvasWidth = labelWidth + 2 + Math.tan(30 * Math.PI / 180) * 28; // same calculation as in delegate
            total += canvasWidth;
        }
        return total;
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: -7
        // Placeholder so the module is visible when there are no windows
        Canvas {
            visible: wins.length === 0
            height: 28
            width: 20
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                // Create angled shape with 30 degree sides
                var angleRad = 30 * Math.PI / 180;
                var offset = Math.tan(angleRad) * height / 2;

                ctx.beginPath();
                ctx.moveTo(offset, 0); // top-left, angled
                ctx.lineTo(width, 0); // top-right
                ctx.lineTo(width - offset, height); // bottom-right, angled
                ctx.lineTo(0, height); // bottom-left
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
                font.pixelSize: 12
            }
        }
        Repeater {
            model: wins
            delegate: Canvas {
                height: 28
                width: label.implicitWidth + 2 + Math.tan(30 * Math.PI / 180) * height
                property bool focused: modelData.focused
                property bool urgent: modelData.urgent
                property string app: modelData.app
                property string title: modelData.title
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    // Create angled shape with 30 degree sides
                    var angleRad = 30 * Math.PI / 180;
                    var offset = Math.tan(angleRad) * height / 2;

                    ctx.beginPath();
                    ctx.moveTo(offset, 0); // top-left, angled
                    ctx.lineTo(width, 0); // top-right
                    ctx.lineTo(width - offset, height); // bottom-right, angled
                    ctx.lineTo(0, height); // bottom-left
                    ctx.closePath();

                    ctx.fillStyle = focused ? C.Theme.wsActiveBg : C.Theme.wsBg;
                    ctx.fill();
                    ctx.strokeStyle = urgent ? C.Theme.red : C.Theme.wsBorder;
                    ctx.lineWidth = focused ? 2 : 1;
                    ctx.stroke();
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
                        text: root.shortLabel(modelData.app, modelData.title)
                        color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function (mouse) {
                        if (mouse.button === Qt.LeftButton && root.compositor === "sway") {
                            run.command = ["bash", "-lc", "swaymsg '[con_id=" + modelData.id + "] focus'"];
                            run.running = true;
                        }
                    }
                    onPressed: function (mouse) {
                        if (mouse.button === Qt.RightButton && root.compositor === "sway") {
                            run.command = ["bash", "-lc", "swaymsg '[con_id=" + modelData.id + "] kill'"];
                            run.running = true;
                        }
                    }
                    hoverEnabled: true
                    onEntered: C.Tooltip.show(root, modelData.title || modelData.app || "?")
                    onExited: C.Tooltip.hide()
                }
            }
        }
    }

    Process {
        id: run
    }

    // Detect compositor
    Process {
        id: detect
        command: ["bash", "-lc", "pgrep -x niri >/dev/null && echo niri || (pgrep -x sway >/dev/null && echo sway || echo unknown)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.compositor = this.text.trim()
        }
    }

    // Sway: poll tree and extract windows
    Process {
        id: swayTree
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var tree = JSON.parse(this.text);
                    var list = [];
                    root.collectWindows(tree, list);
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
