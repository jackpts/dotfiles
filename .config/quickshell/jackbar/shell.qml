import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"
import "components" as C

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    exclusiveZone: implicitHeight
    focusable: false

    Rectangle {
        anchors.fill: parent
        color: C.Theme.bg // translucent dark background
    }

    Row {
        id: leftRow
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        UpdatesIndicator {}
        TaskList {}
        Workspaces {}
    }

    Row {
        id: rightRow
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        CpuGauge {}
        MemoryGauge {}
        FreeSpaceGauge {}
        VolumeGauge {}
        NetworkIndicator {}
        ScreenRecorder {}
        ScreenshotButton {}
        BatteryGauge {}
        // Clock
        Item {
            width: 70; height: 40
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "HH:mm, dd MMM")
                color: C.Theme.clock
                font.pixelSize: 14
            }
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }
    }
}
