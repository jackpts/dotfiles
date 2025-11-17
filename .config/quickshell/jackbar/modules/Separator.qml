/*-----------------------------
--- Seperator.qml by andrel ---
-----------------------------*/

import QtQuick

Rectangle {
    id: root
    width: 2
    height: 40  // Fixed height instead of GlobalVariables
    color: "#6c7086"  // Light gray
    opacity: 0.2

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: "#45475a"  // Shadow color
    }
}
