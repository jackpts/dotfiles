import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"
import "components" as C

Variants {
    id: panels
    model: {
        function isUsableScreen(scr) {
            return scr && scr.name && scr.name.indexOf("HEADLESS") !== 0;
        }

        var preferred = Quickshell.env("QS_PANEL_OUTPUT");
        var preferredLower = preferred ? preferred.toLowerCase() : "";

        var allowed = null;
        if (preferred && preferredLower !== "all" && preferred !== "*") {
            allowed = {};
            var parts = preferred.split(/[,\s]+/);
            for (var i = 0; i < parts.length; ++i) {
                var p = parts[i].trim();
                if (p.length)
                    allowed[p] = true;
            }
        }

        var out = [];
        for (var j = 0; j < Quickshell.screens.length; ++j) {
            var s = Quickshell.screens[j];
            if (!isUsableScreen(s))
                continue;
            if (allowed && !allowed[s.name])
                continue;
            out.push(s);
        }

        return out;
    }

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
        id: win
        property var modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 40
        exclusiveZone: implicitHeight
        focusable: false
        color: "transparent"

        Component.onCompleted: {
            if (Quickshell.env("QS_PANEL_DEBUG"))
                console.log("QS panel: created panel on", modelData ? modelData.name : "<null>");
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
}
