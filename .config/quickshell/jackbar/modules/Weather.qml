import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components" as C

Item {
    id: root
    width: Math.max(weatherText.implicitWidth + 40, 36)
    height: C.Theme.panelHeight

    property bool loading: true
    property string textValue: "..."
    property string tooltipText: "Loading weather..."
    property var locations: []
    property string selectedLocationId: "minsk"
    property string selectedLocationName: "Minsk, Belarus"
    property bool menuOpen: false
    property int menuWidth: C.Theme.scale(240)
    property int menuX: 0
    property int menuY: 0

    function locationById(id) {
        for (var i = 0; i < locations.length; i++) {
            if (locations[i].id === id)
                return locations[i];
        }
        return null;
    }

    function closeLocationMenu() {
        menuOpen = false;
    }

    function openLocationMenu(anchor) {
        C.Tooltip.hide();
        var pt = anchor.mapToGlobal(0, anchor.height + C.Theme.scale(6));
        menuX = isFinite(pt.x) ? Math.max(0, Math.round(pt.x)) : 8;
        menuY = isFinite(pt.y) ? Math.max(0, Math.round(pt.y)) : C.Theme.panelHeight + 4;
        menuOpen = true;
    }

    function applyWeatherResult(result) {
        if (result.text)
            root.textValue = result.text;
        if (result.tooltip)
            root.tooltipText = result.tooltip;
        if (result.locationId)
            root.selectedLocationId = result.locationId;
        if (result.location)
            root.selectedLocationName = result.location;
        root.loading = false;
    }

    function refreshWeather() {
        loading = true;
        weatherProc.command = ["bash", "-c", "python3 $HOME/scripts/weather.py --json"];
        weatherProc.running = true;
    }

    function selectLocation(locationId) {
        closeLocationMenu();
        loading = true;
        weatherProc.command = ["bash", "-c", "python3 $HOME/scripts/weather.py --json --set-location " + locationId];
        weatherProc.running = true;
    }

    function openDetailedWeather() {
        var loc = locationById(selectedLocationId) || locationById("minsk");
        var target = loc ? (loc.lat + "," + loc.lon + "?2n") : "Minsk?2n";
        run.command = ["bash", "-c",
            "alacritty --class weather-display --option window.dimensions.columns=85 " +
            "--option window.dimensions.lines=30 --option font.size=12 -e sh -c \"curl -s 'https://wttr.in/" + target + "'; " +
            "echo; echo 'Press any key to exit...'; read -n 1 -s key\""];
        run.running = true;
    }

    Component.onCompleted: {
        locationsProc.running = true;
        refreshWeather();
    }

    Process {
        id: locationsProc
        command: ["bash", "-c", "python3 $HOME/scripts/weather.py --list-locations"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.locations = JSON.parse(text);
                    if (!root.locationById(root.selectedLocationId)) {
                        root.selectedLocationId = "minsk";
                        root.selectedLocationName = "Minsk, Belarus";
                    }
                } catch (e) {
                    console.error("Error parsing weather locations:", e);
                }
            }
        }
    }

    Process {
        id: weatherProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    applyWeatherResult(JSON.parse(text));
                } catch (e) {
                    console.error("Error parsing weather data:", e);
                    root.loading = false;
                }
            }
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: refreshWeather()
    }

    Process { id: run }

    MouseArea {
        id: weatherMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                openLocationMenu(root);
            } else {
                openDetailedWeather();
            }
        }
        onEntered: {
            const html = tooltipText.replace(/\r?\n/g, '<br/>');
            C.Tooltip.show(root, html, false, { maxWidth: 400 });
        }
        onExited: C.Tooltip.hide()
    }

    Item {
        id: weatherSpinner
        anchors.centerIn: parent
        width: 16
        height: 16
        visible: root.loading
        property color strokeColor: C.Theme.text

        Canvas {
            id: weatherSpinnerCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.strokeStyle = weatherSpinner.strokeColor;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, (width - 4) / 2, Math.PI * 0.2, Math.PI * 1.7);
                ctx.stroke();
            }
        }

        NumberAnimation on rotation {
            running: root.loading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
            easing.type: Easing.Linear
        }

        onStrokeColorChanged: weatherSpinnerCanvas.requestPaint()
        Component.onCompleted: weatherSpinnerCanvas.requestPaint()
    }

    Text {
        id: weatherText
        anchors.centerIn: parent
        text: textValue
        color: C.Theme.text
        font.pixelSize: C.Theme.fontLg
        enabled: false
        visible: !root.loading
    }

    PanelWindow {
        id: locationMenuLayer
        visible: root.menuOpen
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        exclusiveZone: 0
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-weathermenu"

        onVisibleChanged: {
            if (visible)
                locationMenuLayer.forceActiveFocus();
        }

        Keys.onEscapePressed: root.closeLocationMenu()

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: root.closeLocationMenu()
        }

        Rectangle {
            id: menuBox
            z: 1
            x: root.menuX
            y: root.menuY
            width: root.menuWidth
            implicitHeight: menuColumn.implicitHeight + C.Theme.scale(16)
            height: implicitHeight
            color: "#1e1e2e"
            border.color: C.Theme.appMenu
            border.width: 1
            radius: 0

            Column {
                id: menuColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: C.Theme.scale(8)
                spacing: C.Theme.scale(2)
                width: menuBox.width - C.Theme.scale(16)

                Text {
                    width: menuColumn.width
                    leftPadding: C.Theme.scale(4)
                    text: "Weather location"
                    color: C.Theme.wsTextActive
                    font.pixelSize: C.Theme.fontSm
                }

                Text {
                    width: menuColumn.width
                    leftPadding: C.Theme.scale(4)
                    text: root.selectedLocationName
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: menuColumn.width
                    height: 1
                    color: "#313244"
                }

                Repeater {
                    model: root.locations
                    delegate: Rectangle {
                        width: menuColumn.width
                        height: C.Theme.scale(28)
                        property bool isSelected: modelData.id === root.selectedLocationId
                        color: locationMouse.containsMouse
                            ? "#313244"
                            : (isSelected ? "#252536" : "transparent")
                        radius: 0

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: C.Theme.scale(8)
                            text: modelData.name
                            color: isSelected ? C.Theme.wsTextActive : C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                            elide: Text.ElideRight
                            width: parent.width - C.Theme.scale(16)
                        }

                        MouseArea {
                            id: locationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectLocation(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
