pragma Singleton
import Quickshell
import QtQuick
import QtQuick.Window
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

        width: Math.min(content.implicitWidth + tip.padding * 2, tip.maxWidth)
        height: Math.min(content.paintedHeight + tip.padding * 2, tip.maxHeight > 0 ? tip.maxHeight : 9999)

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: C.Theme.tooltipBg
            border.color: C.Theme.tooltipBorder
            border.width: 0
            clip: true

            Flickable {
                id: scroller
                anchors.fill: parent
                anchors.margins: tip.padding
                contentWidth: content.width
                contentHeight: content.paintedHeight
                interactive: contentHeight > height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Component.onCompleted: {
                    if (contentHeight > height) {
                        contentY = contentHeight - height
                    }
                }

                Text {
                    id: content
                    width: tip.monospace
                        ? implicitWidth
                        : Math.min(tip.maxWidth - tip.padding * 2, implicitWidth)
                    text: tip.text
                    color: C.Theme.tooltipText
                    font.pixelSize: 14
                    // Use monospace when requested (helps align calendar columns)
                    font.family: tip.monospace ? "JetBrainsMono Nerd Font" : font.family
                    textFormat: Text.RichText
                    wrapMode: tip.monospace ? Text.NoWrap : Text.WordWrap
                }
            }
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
