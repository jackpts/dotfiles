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
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        // color: C.Theme.bg // translucent dark background
        // color: Qt.rgba(0,0,0,0)
        color: "#111111"
        opacity: 0.7
    }

    Row {
        id: leftRow
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        AppMenu {}
        UpdatesIndicator {}
        Weather {}
		TaskList {}
		Item { width: 48; height: 1 }
        Workspaces {}
    }

    Row {
        id: rightRow
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 20
        // RedShift {}
        // Separator {}
        MusicPlayer {}
        Separator {}
        Shazam {}
        Separator {}
        CpuGauge {}
        MemoryGauge {}
        FreeSpaceGauge {}
        VolumeGauge {}
        Separator {}
        Brightness {}
        NetworkIndicator {}
        BluetoothIndicator {}
        LanguageSwitcher {}
        ScreenRecorder {}
        ScreenshotButton {}
        Clipboard {}
        NotificationIndicator {}
        // BlueLight {}
        BatteryGauge {}
        // Tray {}
        Clock {}
    }
}
