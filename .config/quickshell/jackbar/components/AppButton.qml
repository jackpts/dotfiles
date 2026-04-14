import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    width: parent ? (parent.width - 24) / 4 : 100
    height: 70
    color: mouseArea.containsMouse ? "#313244" : "#282839"
    radius: 10
    border.width: 0

    property string iconChar: ""
    property string appName: ""
    signal clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Text {
            text: iconChar
            color: "#cdd6f4"
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: appName
            color: "#cdd6f4"
            font.pixelSize: 11
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
