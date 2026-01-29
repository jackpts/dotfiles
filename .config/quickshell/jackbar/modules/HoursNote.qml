import Quickshell
import QtQuick
import Qt.labs.settings 1.1
import "../components" as C

Item {
    id: root
    width: 36
    height: 40

    property alias text: noteInput.text
    property string placeholder: "hrs"
    property int maxChars: 4

    function tooltipMessage() {
        const value = noteInput.text.length ? noteInput.text : root.placeholder
        return value + " hours to log work in JIRA"
    }

    Settings {
        id: store
        category: "jackbar.hoursNote"
        property string value: ""
    }

    MouseArea {
        id: clickCatcher
        anchors.fill: parent
        hoverEnabled: true
        onClicked: noteInput.forceActiveFocus()
        onEntered: C.Tooltip.show(root, root.tooltipMessage())
        onExited: C.Tooltip.hide()
    }

    TextInput {
        id: noteInput
        anchors.fill: parent
        anchors.margins: 0
        font.pixelSize: 16
        color: C.Theme.green
        maximumLength: root.maxChars
        selectByMouse: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        cursorVisible: activeFocus
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhPreferNumbers
        text: store.value
        onTextChanged: {
            store.value = text
            if (clickCatcher.containsMouse)
                C.Tooltip.show(root, root.tooltipMessage())
        }
        onActiveFocusChanged: {}
        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Escape) {
                focus = false
                event.accepted = true
            }
        }
        opacity: activeFocus ? 1 : 0
    }

    Text {
        id: display
        anchors.centerIn: parent
        text: noteInput.text.length ? noteInput.text : root.placeholder
        color: noteInput.text.length ? C.Theme.green : C.Theme.textMuted
        font.pixelSize: 16
        visible: !noteInput.activeFocus
        enabled: false
    }
}
