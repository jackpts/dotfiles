import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"
import "components" as C

Variants {
    id: panels
    objectName: "panels"
    model: Quickshell.screens

    Component.onCompleted: {
        if (Quickshell.env("QS_PANEL_DEBUG")) {
            var screens = [];
            for (var i = 0; i < Quickshell.screens.length; ++i) {
                var s = Quickshell.screens[i];
                if (s)
                    screens.push(s.name + " " + s.width + "x" + s.height);
            }

            var creating = [];
            for (var k = 0; k < panels.model.length; ++k) {
                var s2 = panels.model[k];
                if (s2)
                    creating.push(s2.name);
            }

            console.log("QS panel: QS_PANEL_OUTPUT=", Quickshell.env("QS_PANEL_OUTPUT"), "available=", screens.join(", "), "creating=", creating.join(", "));
        }
    }

    delegate: PanelWindow {
        id: barWindow
        required property var modelData
        readonly property bool qsUsableScreen: modelData && modelData.name && modelData.name.indexOf("HEADLESS") !== 0
        readonly property bool qsAllowedScreen: {
            var preferred = Quickshell.env("QS_PANEL_OUTPUT");
            var preferredLower = preferred ? preferred.toLowerCase() : "";
            if (!preferred || preferredLower === "all" || preferred === "*")
                return true;

            var parts = preferred.split(/[,\s]+/);
            for (var i = 0; i < parts.length; ++i) {
                var p = parts[i].trim();
                if (p.length && p === modelData.name)
                    return true;
            }

            return false;
        }

        property bool barHovered: false
        readonly property bool barAutohide: C.SettingsStore.barAutohide
        readonly property bool barForceShow: settingsInd.menuOpen
        readonly property bool barExpanded: !barAutohide || barHovered || barForceShow

        visible: qsUsableScreen && qsAllowedScreen

        screen: modelData
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: barExpanded ? C.Theme.panelHeight : 3
        exclusiveZone: barExpanded ? C.Theme.panelHeight : 0
        focusable: true
        color: "transparent"

        Behavior on implicitHeight {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: {
            if (Quickshell.env("QS_PANEL_DEBUG"))
                console.log("QS panel: created panel on", modelData ? modelData.name : "<null>", "visible=", visible);
        }

        Timer {
            id: hideTimer
            interval: 500
            onTriggered: {
                if (!barWindow.barForceShow)
                    barWindow.barHovered = false
            }
        }

        function keepBar() {
            hideTimer.stop()
            barWindow.barHovered = true
        }

        function maybeHideBar() {
            if (!barWindow.barAutohide)
                return
            if (barWindow.barForceShow)
                return
            hideTimer.restart()
        }

        Rectangle {
            anchors.fill: parent
            color: "#111111"
            opacity: barWindow.barExpanded ? 0.7 : 0.35
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        Item {
            anchors.fill: parent

            // HoverHandler stays active while the cursor is over the bar or any child module
            HoverHandler {
                id: barHover
                onHoveredChanged: {
                    if (hovered)
                        barWindow.keepBar()
                    else
                        barWindow.maybeHideBar()
                }
            }

            Item {
                anchors.fill: parent
                opacity: barWindow.barExpanded ? 1 : 0
                visible: opacity > 0.01
                clip: true
                Behavior on opacity {
                    NumberAnimation { duration: 100 }
                }

                Row {
                    id: leftRow
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    AppMenu {}
                    UpdatesIndicator {}
                    Weather {}
                    TaskList {}
                }

                Item {
                    id: workspaceArea
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: leftRow.right
                    anchors.leftMargin: 2
                    anchors.right: rightRow.left
                    anchors.rightMargin: 2
                    height: parent.height

                    Workspaces {
                        id: workspaces
                        anchors.centerIn: parent
                    }
                }

                Row {
                    id: rightRow
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    // RedShift {}
                    // Separator {}
                    MusicPlayer {}
                    Separator {}
                    Shazam {}
                    Separator {}
                    CpuGauge {}
                    MemoryGauge {}
                    FreeSpaceGauge {}
                    VolumeGauge {}
                    Separator {}
                    SettingsIndicator {
                        id: settingsInd
                    }
                    NetworkIndicator {}
                    BluetoothIndicator {}
                    BillingIndicator {}
                    LanguageSwitcher {}
                    ScreenRecorder {}
                    ScreenshotCapture {}
                    // HoursNote {}
                    Clipboard {}
                    NotificationIndicator {}
                    // BlueLight {}
                    BatteryGauge {}
                    // Tray {}
                    Clock {}
                }
            }
        }
    }
}
