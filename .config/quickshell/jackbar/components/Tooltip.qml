pragma Singleton
import Quickshell
import QtQuick
import "." as C

Singleton {
    id: tip
    property Item target: null
    property string text: ""
    property int padding: 8

    PopupWindow {
        id: popup
        visible: false
        // Anchor relative to the hovered module
        anchor.item: tip.target
        anchor.edges: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: content.implicitWidth + tip.padding * 2
        implicitHeight: content.implicitHeight + tip.padding * 2

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: C.Theme.tooltipBg
            border.color: C.Theme.tooltipBorder
            border.width: 0
        }

        Text {
            id: content
            anchors.centerIn: parent
            text: tip.text
            color: C.Theme.tooltipText
            font.pixelSize: 12
            wrapMode: Text.NoWrap
        }
    }

    function show(item, content) {
        target = item
        text = content
        popup.visible = true
        popup.anchor.updateAnchor()
    }

    function hide() {
        popup.visible = false
    }
}
