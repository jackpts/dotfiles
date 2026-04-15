import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components" as C

Item {
    id: root
    width: 60
    height: C.Theme.panelHeight

    // Visual feedback
    property color activeColor: "red"
    property color inactiveColor: C.Theme.appMenu
    property bool isAppMenuOpen: false
    property bool isPowerMenuOpen: false

    function getIconColor() {
        if (isAppMenuOpen || isPowerMenuOpen) return activeColor;
        return inactiveColor;
    }

    function closeMenus() {
        isAppMenuOpen = false;
        isPowerMenuOpen = false;
    }

    function toggleAppMenu() {
        if (isPowerMenuOpen) isPowerMenuOpen = false;
        isAppMenuOpen = !isAppMenuOpen;
    }

    function togglePowerMenu() {
        if (isAppMenuOpen) isAppMenuOpen = false;
        isPowerMenuOpen = !isPowerMenuOpen;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton) {
                closeMenus();
                reloadProcess.running = true;
                return;
            }

            if (isAppMenuOpen || isPowerMenuOpen) {
                closeMenus();
                return;
            }

            if (mouse.button === Qt.LeftButton) {
                toggleAppMenu();
            } else if (mouse.button === Qt.RightButton) {
                togglePowerMenu();
            }
        }
    }

    Process {
        id: reloadProcess
        command: ["bash", "-lc", "swaymsg reload"]
    }

    // Garuda logo/icon
    Text {
        anchors.fill: parent
        anchors.margins: C.Theme.panelPadding
        text: "󰣇"
        color: root.getIconColor()
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Math.max(
            C.Theme.fontIcon,
            Math.round((C.Theme.panelHeight - C.Theme.scale(10)) * 0.5)
        )
        enabled: false
    }

    // Tooltip
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: C.Tooltip.show(root, "Menu (L) / Power (R)")
        onExited: C.Tooltip.hide()
    }

    // Data models
    C.RecentAppsModel { id: recentModel }
    C.AppListModel { id: appListModel }

    // ==================== App Menu (PanelWindow) ====================
    PanelWindow {
        id: appMenuWindow
        visible: root.isAppMenuOpen
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors {
            top: true
            left: true
        }
        margins.top: 0
        margins.left: 4
        implicitWidth: 500
        implicitHeight: searchInput.text !== "" ? 560 : appMenuContent.implicitHeight + 32
        exclusiveZone: 0
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-appmenu"

        onVisibleChanged: {
            if (visible) {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            border.color: "#4DD0E1"
            border.width: 2
            radius: 0

            ColumnLayout {
                id: appMenuContent
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#313244"
                    radius: 8

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.margins: 8
                        color: "#cdd6f4"
                        font.pixelSize: C.Theme.fontMd
                        selectByMouse: true
                        focus: true

                        onTextChanged: appListModel.filter = text
                        Keys.onEscapePressed: root.isAppMenuOpen = false

                        Text {
                            anchors.fill: parent
                            text: "Search applications..."
                            color: "#6c7086"
                            visible: searchInput.text === ""
                            font.pixelSize: C.Theme.fontMd
                        }
                    }
                }

                // Recently used section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: recentModel.count > 0 && searchInput.text === ""

                    Text {
                        text: "Recently Used"
                        color: "#4DD0E1"
                        font.pixelSize: C.Theme.fontSm
                        font.bold: true
                    }

                    Grid {
                        Layout.fillWidth: true
                        columns: 4
                        spacing: 8

                        Repeater {
                            model: recentModel.model

                            C.AppButton {
                                width: (appMenuContent.width - 24) / 4
                                iconChar: model.icon || "󰣆"
                                appName: model.name || ""
                                onClicked: {
                                    if (!model.exec) return;
                                    appLauncher.launch(model.exec);
                                    recentModel.addRecent(model.name || "", model.exec, model.icon || "󰣆");
                                    root.closeMenus();
                                }
                            }
                        }
                    }
                }

                // All apps section - only visible when searching
                Text {
                    text: "Results"
                    color: "#4DD0E1"
                    font.pixelSize: C.Theme.fontSm
                    font.bold: true
                    visible: searchInput.text !== "" && appListModel.count > 0
                }

                ListView {
                    id: appListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: searchInput.text !== ""
                    model: appListModel.model

                    delegate: Rectangle {
                        width: appListView.width
                        height: 44
                        color: delegateMouseArea.containsMouse ? "#313244" : "transparent"
                        radius: 6

                        MouseArea {
                            id: delegateMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!model.exec) return;
                                appLauncher.launch(model.exec);
                                recentModel.addRecent(model.name || "", model.exec, model.icon || "󰣆");
                                root.closeMenus();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Text {
                                text: model.icon || "󰣆"
                                color: "#cdd6f4"
                                font.pixelSize: C.Theme.fontIcon
                                Layout.preferredWidth: 28
                            }

                            Text {
                                text: model.name || ""
                                color: "#cdd6f4"
                                font.pixelSize: C.Theme.fontMd
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // App launcher process
        Process {
            id: appLauncher
            function launch(exec) {
                if (!exec || exec === "") return;
                command = ["swaymsg", "exec", "--", exec];
                running = true;
            }
        }
    }

    // ==================== Power Menu (PanelWindow) ====================
    PanelWindow {
        id: powerMenuWindow
        visible: root.isPowerMenuOpen
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors {
            top: true
            left: true
        }
        margins.top: 0
        margins.left: 4
        implicitWidth: 420
        implicitHeight: 360
        exclusiveZone: 0
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-powermenu"

        onVisibleChanged: {
            if (visible) {
                powerMenuWindow.forceActiveFocus();
            }
        }

        Keys.onEscapePressed: root.isPowerMenuOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            border.color: "#f38ba8"
            border.width: 2
            radius: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Uptime display
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰔚"
                        color: "#f38ba8"
                        font.pixelSize: C.Theme.fontIcon
                    }

                    Text {
                        text: "Uptime: " + uptimeMonitor.uptime
                        color: "#cdd6f4"
                        font.pixelSize: C.Theme.fontMd
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#313244"
                }

                // Power options grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    C.PowerButton {
                        iconChar: ""
                        label: "Lock"
                        onClicked: {
                            lockProcess.running = true;
                            root.isPowerMenuOpen = false;
                        }
                    }

                    C.PowerButton {
                        iconChar: "󰒲"
                        label: "Suspend"
                        onClicked: {
                            suspendProcess.running = true;
                            root.isPowerMenuOpen = false;
                        }
                    }

                    C.PowerButton {
                        iconChar: "󰍃"
                        label: "Logout"
                        onClicked: {
                            logoutProcess.running = true;
                            root.isPowerMenuOpen = false;
                        }
                    }

                    C.PowerButton {
                        iconChar: "󰑓"
                        label: "Reboot"
                        onClicked: {
                            rebootProcess.running = true;
                            root.isPowerMenuOpen = false;
                        }
                    }

                    C.PowerButton {
                        iconChar: ""
                        label: "Shutdown"
                        Layout.columnSpan: 2
                        onClicked: {
                            shutdownProcess.running = true;
                            root.isPowerMenuOpen = false;
                        }
                    }
                }
            }
        }

        C.UptimeMonitor { id: uptimeMonitor }

        Process { id: lockProcess; command: ["bash", "-lc", "$HOME/scripts/lock_with_matrix.sh"] }
        Process { id: suspendProcess; command: ["bash", "-lc", "amixer set Master mute && systemctl suspend && $HOME/scripts/lock_with_matrix.sh"] }
        Process { id: logoutProcess; command: ["bash", "-lc", "swaymsg exit"] }
        Process { id: rebootProcess; command: ["bash", "-lc", "systemctl reboot"] }
        Process { id: shutdownProcess; command: ["bash", "-lc", "systemctl poweroff"] }
    }
}
