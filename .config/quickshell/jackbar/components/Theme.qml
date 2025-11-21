pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Backgrounds and text (from Waybar style.css)
    property color bg: "#000000B3"                    // rgba(0, 0, 0, 0.7) - translucent dark background
    property color text: "#cdd6f4"                    // light text
    property color textMuted: "#ccccccb3"             // rgba(204, 204, 204, 0.7)
    property color track: "#444444"                   // gauge track ring

    // Palette (from Waybar)
    property color red: "#f53c3c"
    property color green: "#51a37a"
    property color greenCharging: "#26a65b"
    property color yellow: "#ffcc00"
    property color blue: "#215fad"
    property color grayMuted: "#90b1b1"

    // Module accent colors (matching Waybar CSS)
    property color cpu: "#cddceb"                     // #cddceb from CSS
    property color memory: "#cddceb"                  // #cddceb from CSS
    property color memoryGauge: "#bb2288"             // Accent used by MemoryGauge
    // AppMenu (Waybar Garuda teal)
    property color appMenu: "#4DD0E1"                 // #4DD0E1
    property color appMenuHover: "#26C6DA"            // #26C6DA
    // Language Switcher accents
    property color languageRu: "#6495ed"
    property color languageUs: "#e15cd9"
    property color freeOk: green                      // #51a37a
    property color freeLow: red                       // #f53c3c
    property color volumeActive: "#f1c40fb3"          // rgba(241, 196, 15, 0.7)
    property color volumeMuted: grayMuted             // #90b1b1
    property color batteryOk: blue                    // #215fad
    property color batteryCharging: greenCharging     // #26a65b
    property color batteryCritical: red               // #f53c3c
    property color networkWifi: "#cc88ff"             // #c8f
    property color networkEthernet: "#6699aa"         // #69a
    property color networkDisconnected: red           // #f53c3c
    // Bluetooth Indicator accents
    property color bluetoothActive: "#89b4fa"
    property color bluetoothInactive: "#6c7086"
    // Clock and calendar
    property color clock: "#ccddaa"                   // #cda
    property color calendarHeader: "#ff6699"
    property color calendarDow: "#7CD37C"
    property color calendarToday: "#ffcc66"
    property color updatesDefault: yellow             // #ffcc00
    property color updatesAvailable: "#22cc55"        // #22cc55
    property color updatesNone: blue                  // #215fad
    property color screenshotIcon: "#cccccccc"        // rgba(204, 204, 204, 0.8)
    property color recorderOn: "#eb4d4bcc"            // rgba(235, 77, 75, 0.8)
    property color recorderOff: "#cccccccc"           // rgba(204, 204, 204, 0.8)

    // Workspace/Task styling (from Waybar taskbar/workspaces)
    property color wsBg: "#1f1923"                    // #1f1923 from taskbar button
    property color wsActiveBg: "#70597f"              // #70597f from taskbar button.active
    property color wsBorder: "#666666"                // #666 from workspaces button separator
    property color wsText: textMuted                  // rgba(204, 204, 204, 0.7)
    property color wsTextActive: "#debcdf"            // #debcdf from workspaces button.active
    
    // Tooltip (from Waybar tooltip)
    // Nearly opaque black background (alpha ≈ 0.95)
    // Use ARGB format: #AARRGGBB -> F2 alpha, 00 red, 00 green, 00 blue
    property color tooltipBg: "#F2000000"             // rgba(0, 0, 0, 0.95)
    property color tooltipText: text                  // #cdd6f4
    // Match border to background so no light edge is visible
    property color tooltipBorder: "#F2000000"
}
