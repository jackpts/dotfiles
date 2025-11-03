import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: weatherText.implicitWidth + 20
    height: 40
    
    property string textValue: "..."
    property string tooltipText: "Loading weather..."
    
    Process {
        id: weatherProc
        command: ["bash", "-c", "python3 $HOME/scripts/weather.py --json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text)
                    if (result.text) root.textValue = result.text
                    if (result.tooltip) root.tooltipText = result.tooltip
                } catch (e) {
                    console.error("Error parsing weather data:", e)
                }
            }
        }
    }
    
    // Update every 15 minutes (900000 ms)
    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }
    
    Process { id: run }
    
    // Click handler to show detailed weather
    MouseArea {
        anchors.fill: parent
        onClicked: {
            run.command = ["bash", "-c", 
                "alacritty --class weather-display --option window.dimensions.columns=85 " +
                "--option window.dimensions.lines=30 --option font.size=12 -e sh -c \"curl -s 'https://wttr.in/?2n'; " +
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
        font.pixelSize: 14
        enabled: false  // Make text transparent to mouse events
    }
    
    // Tooltip with detailed weather info
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: C.Tooltip.show(root, tooltipText)
        onExited: C.Tooltip.hide()
    }
}
