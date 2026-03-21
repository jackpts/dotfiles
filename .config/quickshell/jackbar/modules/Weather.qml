import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: Math.max(weatherText.implicitWidth + 20, 36)
    height: 50
    property bool loading: true
    property string textValue: "..."
    property string tooltipText: "Loading weather..."
    
    function refreshWeather() {
        loading = true
        weatherProc.running = true
    }

    Component.onCompleted: refreshWeather()
    
    Process {
        id: weatherProc
        command: ["bash", "-c", "python3 $HOME/scripts/weather.py --json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text)
                    if (result.text) root.textValue = result.text
                    if (result.tooltip) root.tooltipText = result.tooltip
                    root.loading = false
                } catch (e) {
                    console.error("Error parsing weather data:", e)
                    root.loading = false
                }
            }
        }
    }
    
    // Update every 15 minutes (900000 ms)
    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: refreshWeather()
    }
    
    Process { id: run }
    
    // Weather spinner
    Item {
        id: weatherSpinner
        anchors.centerIn: parent
        width: 16
        height: 16
        visible: root.loading
        property color strokeColor: "#ffffff"

        Canvas {
            id: weatherSpinnerCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.strokeStyle = weatherSpinner.strokeColor
                ctx.beginPath()
                ctx.arc(width/2, height/2, (width-4)/2, Math.PI * 0.2, Math.PI * 1.7)
                ctx.stroke()
            }
        }

        NumberAnimation on rotation {
            running: root.loading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 900
            easing.type: Easing.Linear
        }

        onStrokeColorChanged: weatherSpinnerCanvas.requestPaint()
        Component.onCompleted: weatherSpinnerCanvas.requestPaint()
    }

    // Click handler to show detailed weather
    MouseArea {
        anchors.fill: parent
        onClicked: {
            run.command = ["bash", "-c", 
                "alacritty --class weather-display --option window.dimensions.columns=85 " +
                "--option window.dimensions.lines=30 --option font.size=14 -e sh -c \"curl -s 'https://wttr.in/?2n'; " +
                "echo; echo 'Press any key to exit...'; read -n 1 -s key\""]
            run.running = true
        }
    }
    
    // Weather text display
    Text {
        id: weatherText
        anchors.centerIn: parent
        text: textValue
        color: C.Theme.text
        font.pixelSize: 18
        enabled: false  // Make text transparent to mouse events
        visible: !root.loading
    }
    
    // Tooltip with detailed weather info
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: {
            // Preserve line breaks in tooltip while keeping normal wrapping
            const html = tooltipText.replace(/\r?\n/g, '<br/>')
            C.Tooltip.show(root, html)
        }
        onExited: C.Tooltip.hide()
    }
}
