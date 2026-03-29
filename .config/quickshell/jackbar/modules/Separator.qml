/*-----------------------------
--- Seperator.qml by andrel ---
-----------------------------*/

import QtQuick

Rectangle {
    id: root
    width: 2
    height: C.Theme.panelHeight  // Match panel height for proper alignment
    color: "#6c7086"  // Light gray
    opacity: 0.2

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: "#45475a"  // Shadow color
    }
}
