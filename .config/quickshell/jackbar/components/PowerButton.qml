import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 60
    color: mouseArea.containsMouse ? "#313244" : "#282839"
    radius: 10
    border.width: 0

    property string iconChar: ""
    property string label: ""
    signal clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            text: iconChar
            color: "#f38ba8"
            font.pixelSize: 22
        }

        Text {
            text: label
            color: "#cdd6f4"
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
        }
    }
}
