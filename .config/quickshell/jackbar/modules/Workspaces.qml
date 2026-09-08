pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../components" as C

Item {
    id: root
    height: C.Theme.panelHeight
    property int minVisible: 4
    property int minSlots: minVisible
    property int slotWidth: C.Theme.scale(28)
    width: Math.max(items.implicitWidth, minSlots * (slotWidth + items.spacing) - items.spacing)
    property string compositor: "unknown"
    property var spaces: []

    function emptySlot(num) {
        return {
            num: num,
            name: String(num),
            focused: false,
            urgent: false
        };
    }

    function fillWorkspaceSlots(existing) {
        var byNum = {};
        var highest = 0;
        for (var i = 0; i < existing.length; i++) {
            var n = Number(existing[i].num);
            if (!isFinite(n) || n < 1)
                continue;
            byNum[n] = existing[i];
            if (n > highest)
                highest = n;
        }

        // Always show at least minVisible slots, plus one empty slot after the
        // last existing workspace so a window can be moved further.
        var count = Math.max(root.minVisible, highest + 1);
        var filled = [];
        for (var num = 1; num <= count; num++)
            filled.push(byNum[num] ? byNum[num] : emptySlot(num));
        return filled;
    }

    Row {
        id: items
        anchors.verticalCenter: parent.verticalCenter
        spacing: C.Theme.scale(4)
        Repeater {
            model: spaces
            delegate: Item {
                id: workspaceSlot
                required property var modelData
                width: root.slotWidth
                height: C.Theme.scale(28)
                layer.enabled: true
                layer.smooth: true
                transformOrigin: Item.Bottom
                property bool isFocused: !!modelData.focused
                property bool isUrgent: !!modelData.urgent
                property real baseY: C.Theme.scale(2)
                property real bounceOffset: 0

                scale: isFocused ? 1.05 : 0.92
                y: baseY + bounceOffset

                Behavior on scale {
                    SpringAnimation {
                        spring: 4
                        damping: 0.28
                        mass: 0.7
                    }
                }

                SequentialAnimation on bounceOffset {
                    id: focusBounce
                    running: false
                    NumberAnimation {
                        to: -C.Theme.scale(4)
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                    PauseAnimation {
                        duration: 90
                    }
                    NumberAnimation {
                        to: 0
                        duration: 220
                        easing.type: Easing.OutBounce
                    }
                    onStopped: workspaceSlot.bounceOffset = 0
                }

                onModelDataChanged: {
                    triangleCanvas.requestPaint();
                    haloCanvas.requestPaint();
                    if (!isFocused)
                        bounceOffset = 0;
                }

                onIsFocusedChanged: {
                    triangleCanvas.requestPaint();
                    haloCanvas.requestPaint();
                    if (isFocused) {
                        haloFlash.restart();
                        focusBounce.restart();
                    } else {
                        haloFlash.stop();
                        focusBounce.stop();
                        haloLayer.opacity = 0;
                        haloLayer.scale = 0.9;
                        bounceOffset = 0;
                    }
                }

                onIsUrgentChanged: triangleCanvas.requestPaint()

                Item {
                    id: haloLayer
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    z: -1
                    opacity: 0
                    scale: 0.9
                    visible: opacity > 0
                    transformOrigin: Item.Center

                    Canvas {
                        id: haloCanvas
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            ctx.beginPath();
                            ctx.moveTo(width / 2, -2);
                            ctx.lineTo(width + 2, height + 2);
                            ctx.lineTo(-2, height + 2);
                            ctx.closePath();

                            var gradient = ctx.createLinearGradient(width / 2, 0, width / 2, height);
                            gradient.addColorStop(0, C.Theme.wsActiveBg + "80");
                            gradient.addColorStop(1, C.Theme.wsActiveBg + "00");
                            ctx.fillStyle = gradient;
                            ctx.fill();
                        }
                    }
                }

                SequentialAnimation {
                    id: haloFlash
                    running: false
                    PropertyAction {
                        target: haloLayer
                        property: "scale"
                        value: 0.85
                    }
                    PropertyAction {
                        target: haloLayer
                        property: "opacity"
                        value: 0.45
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: haloLayer
                            property: "scale"
                            to: 1.35
                            duration: 340
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: haloLayer
                            property: "opacity"
                            to: 0
                            duration: 340
                            easing.type: Easing.OutQuad
                        }
                    }
                    onStopped: {
                        haloLayer.opacity = 0;
                        haloLayer.scale = 0.9;
                    }
                }

                Canvas {
                    id: triangleCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        // Draw triangle
                        ctx.beginPath();
                        ctx.moveTo(width / 2, 0);
                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height);
                        ctx.closePath();

                        // Fill with background color
                        ctx.fillStyle = modelData.focused ? C.Theme.wsActiveBg : C.Theme.wsBg;
                        ctx.fill();

                        // Draw border
                        ctx.strokeStyle = modelData.urgent ? C.Theme.red : C.Theme.wsBorder;
                        ctx.lineWidth = modelData.focused ? 2 : 1;
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: C.Theme.scale(1)
                    text: modelData.num
                    color: modelData.focused ? C.Theme.wsTextActive : C.Theme.wsText
                    font.pixelSize: C.Theme.fontSm
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.compositor === "sway") {
                            run.command = ["bash", "-lc", "swaymsg workspace number " + modelData.num];
                            run.running = true;
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
        onWheel: function (wheel) {
            if (root.compositor === "sway") {
                run.command = ["bash", "-lc", wheel.angleDelta.y > 0 ? "swaymsg workspace next" : "swaymsg workspace prev"];
                run.running = true;
            }
        }
    }

    Process {
        id: run
    }

    Process {
        id: detect
        command: ["bash", "-lc", "pgrep -x sway >/dev/null && echo sway || echo unknown"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.compositor = this.text.trim()
        }
    }

    Process {
        id: swayWs
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text);
                    var mapped = [];
                    for (var i = 0; i < arr.length; i++) {
                        var n = Number(arr[i].num);
                        if (!isFinite(n) || n < 1)
                            continue;
                        mapped.push({
                            num: n,
                            name: arr[i].name || String(n),
                            focused: !!arr[i].focused,
                            urgent: !!arr[i].urgent
                        });
                    }
                    root.spaces = root.fillWorkspaceSlots(mapped);
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.compositor === "sway") {
                swayWs.command = ["bash", "-lc", "swaymsg -r -t get_workspaces"];
                swayWs.running = true;
            }
        }
    }
}
