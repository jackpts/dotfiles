import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"
import "components" as C

Variants {
    id: panels
    model: Quickshell.screens

    Component.onCompleted: {
        if (Quickshell.env("QS_PANEL_DEBUG")) {
            var screens = [];
            for (var i = 0; i < Quickshell.screens.length; ++i) {
                var s = Quickshell.screens[i];
                if (s)
                    screens.push(s.name + " " + s.width + "x" + s.height);
            }

            var creating = [];
            for (var k = 0; k < panels.model.length; ++k) {
                var s2 = panels.model[k];
                if (s2)
                    creating.push(s2.name);
            }

            console.log("QS panel: QS_PANEL_OUTPUT=", Quickshell.env("QS_PANEL_OUTPUT"), "available=", screens.join(", "), "creating=", creating.join(", "));
        }
    }

    delegate: PanelWindow {
        required property var modelData
        readonly property bool qsUsableScreen: modelData && modelData.name && modelData.name.indexOf("HEADLESS") !== 0
        readonly property bool qsAllowedScreen: {
            var preferred = Quickshell.env("QS_PANEL_OUTPUT");
            var preferredLower = preferred ? preferred.toLowerCase() : "";
            if (!preferred || preferredLower === "all" || preferred === "*")
                return true;

            var parts = preferred.split(/[,\s]+/);
            for (var i = 0; i < parts.length; ++i) {
                var p = parts[i].trim();
                if (p.length && p === modelData.name)
                    return true;
            }

            return false;
        }

        visible: qsUsableScreen && qsAllowedScreen

        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 40
        exclusiveZone: visible ? implicitHeight : 0
        focusable: true
        color: "transparent"

        Component.onCompleted: {
            if (Quickshell.env("QS_PANEL_DEBUG"))
                console.log("QS panel: created panel on", modelData ? modelData.name : "<null>", "visible=", visible);
        }

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
        }

        Item {
            id: workspaceArea
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: leftRow.right
            anchors.leftMargin: 12
            anchors.right: rightRow.left
            anchors.rightMargin: 12
            height: parent.height

            Workspaces {
                id: workspaces
                anchors.centerIn: parent
            }
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
            HoursNote {}
            Clipboard {}
            NotificationIndicator {}
            // BlueLight {}
            BatteryGauge {}
            // Tray {}
            Clock {}
        }
    }
}
