/*------------------------
--- Tray.qml by andrel ---
------------------------*/

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../components" as C

Row {
    id: root
    height: C.Theme.panelHeight
    spacing: C.Theme.scale(6)
    
    Repeater {
        model: SystemTray.items.values
        delegate: Item {
            id: systemTrayItem
            required property var modelData
            
            width: C.Theme.scale(18)
            height: C.Theme.scale(18)
            anchors.verticalCenter: parent.verticalCenter
            
            Image {
                anchors.fill: parent
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                
                onEntered: {
                    if (modelData.title) {
                        C.Tooltip.show(systemTrayItem, modelData.title)
                    }
                }
                
                onExited: C.Tooltip.hide()
                
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    }
                }
                
                onWheel: (wheel) => {
                    modelData.scroll(wheel.angleDelta.y / 120, false)
                }
            }
        }
    }
}
