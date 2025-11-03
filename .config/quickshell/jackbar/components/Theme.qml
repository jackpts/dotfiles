pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Backgrounds and text
    property color bg: "#000000B3"         // translucent dark background
    property color text: "#cdd6f4"         // light text
    property color track: "#444"           // gauge track ring

    // Palette
    property color red: "#f53c3c"
    property color green: "#51a37a"
    property color greenCharging: "#26a65b"
    property color yellow: "#ffcc00"
    property color blue: "#215fad"
    property color grayMuted: "#90b1b1"

    // Module accent colors
    property color cpu: "#cddceb"
    property color memory: "#cdd6f4"
    property color freeOk: green
    property color freeLow: red
    property color volumeActive: "#f1c40f"
    property color volumeMuted: grayMuted
    property color batteryOk: green
    property color batteryCharging: greenCharging
    property color batteryCritical: red
    property color networkWifi: "#c8f"
    property color networkEthernet: "#cdd6f4"
    property color networkDisconnected: red
    property color clock: "#cda"
    property color updatesDefault: yellow
    property color updatesAvailable: "#22cc55"
    property color updatesNone: blue

    // Workspace/Task styling
    property color wsBg: "#1f1923"
    property color wsActiveBg: "#70597f"
    property color wsBorder: "#666666"
    property color wsText: text
    property color wsTextActive: "#debcdf"
}
