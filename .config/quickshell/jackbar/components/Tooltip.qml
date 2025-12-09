pragma Singleton
import Quickshell
import QtQuick
import "." as C

Singleton {
    id: tip
    property Item target: null
    property string text: ""
    property int padding: 8
    property bool monospace: false
    // Optional per-call sizing overrides
    property int maxWidth: 280
    property int maxHeight: -1 // -1 means no cap

    PopupWindow {
        id: popup
        visible: false
        // Anchor relative to the hovered module
        anchor.item: tip.target
        anchor.edges: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: content.width + tip.padding * 2
        implicitHeight: (tip.maxHeight > 0
            ? Math.min(content.paintedHeight + tip.padding * 2, tip.maxHeight)
            : content.paintedHeight + tip.padding * 2)

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: C.Theme.tooltipBg
            border.color: C.Theme.tooltipBorder
            border.width: 0
        }

        Text {
            id: content
            anchors.centerIn: parent
            text: tip.text
            color: C.Theme.tooltipText
            font.pixelSize: 14
            // Use monospace when requested (helps align calendar columns)
            font.family: tip.monospace ? "JetBrainsMono Nerd Font" : font.family
            textFormat: Text.RichText
            wrapMode: tip.monospace ? Text.NoWrap : Text.WordWrap
            // When monospace calendar is shown, avoid wrapping to keep columns aligned
            width: tip.monospace ? implicitWidth : Math.min(tip.maxWidth, implicitWidth)
        }
    }

    function show(item, content, useMonospace, opts) {
        target = item
        text = content
        monospace = !!useMonospace
        // Apply optional overrides safely
        maxWidth = (opts && opts.maxWidth) ? opts.maxWidth : 280
        maxHeight = (opts && opts.maxHeight) ? opts.maxHeight : -1
        popup.visible = true
        popup.anchor.updateAnchor()
    }

    function hide() {
        popup.visible = false
    }
}
