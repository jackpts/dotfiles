import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32
    height: C.Theme.panelHeight

    property bool menuOpen: false
    property double _menuClosedAt: 0

    function toggleMenu() {
        if (Date.now() - root._menuClosedAt < 250)
            return
        root.menuOpen = !root.menuOpen
        if (root.menuOpen)
            C.Tooltip.hide()
    }

    function showHoverTooltip() {
        if (root.menuOpen || !area.containsMouse)
            return
        C.Tooltip.show(root, "Settings")
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onEntered: showHoverTooltip()
        onExited: {
            if (!root.menuOpen)
                C.Tooltip.hide()
        }
        onClicked: toggleMenu()
    }

    Text {
        anchors.centerIn: parent
        text: "󰒓"
        color: root.menuOpen ? C.Theme.yellow : (area.containsMouse ? C.Theme.yellow : C.Theme.text)
        font.pixelSize: C.Theme.fontIcon
    }

    SettingsPanel {
        anchorItem: root
        menuOpen: root.menuOpen
        maxHeight: {
            var win = QsWindow.window
            if (win && win.screen)
                return Math.max(240, win.screen.height - C.Theme.panelHeight - 36)
            return 640
        }
        onDismissed: {
            root.menuOpen = false
            root._menuClosedAt = Date.now()
        }
    }
}
