import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

PopupWindow {
    id: root
    property Item anchorItem: null
    property bool menuOpen: false

    readonly property string script: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/modules/settings-panel.sh"

    property int brightnessCur: 0
    property int brightnessMax: 100
    readonly property real brightnessPct: brightnessMax > 0 ? brightnessCur / brightnessMax : 0
    property int textSize: C.SettingsStore.fontSize
    property real outputScale: C.SettingsStore.outputScale
    property bool barAutohide: C.SettingsStore.barAutohide
    property string wallpaperName: ""
    property var themeColors: []
    property string lastPickedColor: ""
    property bool themeBusy: false
    property bool reminderExpanded: false
    property string reminderText: ""
    property int reminderMinutes: 5
    property string reminderStatus: ""
    readonly property var reminderPresets: [1, 5, 10, 15, 30, 60]

    // Voxtype / Whisper
    property string voxtypeClass: "stopped"
    property string voxtypeTooltip: "Voxtype"
    property string voxtypeModel: ""
    property string voxtypeBackend: ""
    property string voxtypeDaemon: "stopped" // running | starting | stopped | missing
    property bool voxtypeAvailable: false

    readonly property string voxtypeScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/modules/voxtype-status.sh"

    readonly property var scaleOptions: [
        { label: "1x", value: 1 },
        { label: "1.25x", value: 1.25 },
        { label: "1.6x", value: 1.6 },
        { label: "2x", value: 2 },
        { label: "3x", value: 3 }
    ]

    signal dismissed()

    property int maxHeight: 640

    visible: menuOpen
    grabFocus: true
    color: "transparent"
    // Hang from the bottom-right of the settings icon, same gap as module tooltips.
    // Keep the window short so it always fits under the bar; content scrolls inside.
    // SlideX only — never SlideY, or a too-tall popup is pushed down off the bar.
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.SlideX
    anchor.margins.top: 6
    implicitWidth: 332
    implicitHeight: Math.min(480, Math.max(360, maxHeight))

    onVisibleChanged: {
        if (visible) {
            flick.contentY = 0
            refreshAll()
            pinAnchor()
            anchorSync.restart()
        } else {
            dismissed()
        }
    }

    function pinAnchor() {
        if (root.visible && root.anchorItem)
            root.anchor.updateAnchor()
    }

    // Bar autohide expands over ~120ms; re-pin after that so Y stays under the bar.
    Timer {
        id: anchorSync
        interval: 180
        repeat: false
        onTriggered: root.pinAnchor()
    }

    Timer {
        id: scrollReminder
        interval: 50
        repeat: false
        onTriggered: {
            var y = reminderSection.y
            var bottom = y + reminderSection.height + 8
            var viewBottom = flick.contentY + flick.height
            var maxY = Math.max(0, flick.contentHeight - flick.height)
            if (bottom > viewBottom)
                flick.contentY = Math.max(0, Math.min(maxY, bottom - flick.height))
            else if (y < flick.contentY)
                flick.contentY = Math.max(0, y)
        }
    }

    function restartProc(p) {
        p.running = false
        p.running = true
    }

    function refreshAll() {
        root.textSize = C.SettingsStore.fontSize
        root.outputScale = C.SettingsStore.outputScale
        root.barAutohide = C.SettingsStore.barAutohide
        brightnessGet.command = [root.script, "brightness", "get"]
        restartProc(brightnessGet)
        fontGet.command = [root.script, "font", "get"]
        restartProc(fontGet)
        scaleGet.command = [root.script, "scale", "get"]
        restartProc(scaleGet)
        wallpaperGet.command = [root.script, "wallpaper", "name"]
        restartProc(wallpaperGet)
        themeColorsGet.command = [root.script, "theme", "colors"]
        restartProc(themeColorsGet)
        refreshVoxtype()
        colorPickRead.command = [
            "bash", "-lc",
            "f=\"${XDG_RUNTIME_DIR:-/tmp}/jackbar-colorpick.txt\"; [ -f \"$f\" ] && cat \"$f\" || true"
        ]
        restartProc(colorPickRead)
    }

    function refreshVoxtype() {
        voxtypeOnce.command = [root.voxtypeScript, "once"]
        restartProc(voxtypeOnce)
        voxtypeDaemonGet.command = [root.voxtypeScript, "daemon", "status"]
        restartProc(voxtypeDaemonGet)
    }

    function parseVoxtypeJson(raw) {
        try {
            var j = JSON.parse((raw || "").trim())
            root.voxtypeAvailable = j.available !== false && j.class !== "missing"
            root.voxtypeClass = j.class || j.alt || "stopped"
            root.voxtypeTooltip = j.tooltip || ("Voxtype: " + root.voxtypeClass)
            root.voxtypeModel = j.model || ""
            root.voxtypeBackend = j.backend || ""
        } catch (e) {}
    }

    function toggleVoxtypeDaemon() {
        voxtypeDaemonToggle.command = [root.voxtypeScript, "daemon", "toggle"]
        restartProc(voxtypeDaemonToggle)
    }

    function toggleVoxtypeRecord() {
        voxtypeRecord.command = [root.voxtypeScript, "toggle"]
        restartProc(voxtypeRecord)
        voxtypeRefreshTimer.restart()
    }

    function openVoxtypeConfig() {
        voxtypeConfig.command = [root.voxtypeScript, "config"]
        restartProc(voxtypeConfig)
    }

    function voxtypeStateLabel() {
        if (!root.voxtypeAvailable || root.voxtypeClass === "missing")
            return "Not installed"
        if (root.voxtypeDaemon === "running") {
            if (root.voxtypeClass === "recording")
                return "Recording"
            if (root.voxtypeClass === "transcribing")
                return "Transcribing"
            return "Ready"
        }
        if (root.voxtypeDaemon === "starting")
            return "Starting…"
        return "Daemon stopped"
    }

    function setBrightnessPct(pct) {
        pct = Math.max(1, Math.min(100, Math.round(pct)))
        brightnessSet.command = [root.script, "brightness", "set", String(pct)]
        restartProc(brightnessSet)
    }

    function setTextSize(px) {
        px = Math.max(10, Math.min(20, Math.round(px)))
        root.textSize = px
        C.SettingsStore.setFontSize(px)
    }

    function setScale(factor) {
        root.outputScale = factor
        C.SettingsStore.setOutputScale(factor)
    }

    function setAutohide(on) {
        root.barAutohide = on
        C.SettingsStore.setBarAutohide(on)
    }

    function openWallpaper() {
        wallpaperOpen.command = [root.script, "wallpaper", "open"]
        restartProc(wallpaperOpen)
    }

    function applyTheme() {
        root.themeBusy = true
        themeApply.command = [root.script, "theme", "apply"]
        restartProc(themeApply)
    }

    function runColorPicker() {
        // Spawn detached picker, then close panel so grabFocus releases Wayland pointer
        colorPicker.command = [root.script, "colorpicker"]
        restartProc(colorPicker)
    }

    function setReminder() {
        var text = (root.reminderText || "").trim()
        var mins = Math.max(1, Math.round(root.reminderMinutes))
        if (!text.length) {
            root.reminderStatus = "Enter a reminder text"
            return
        }
        root.reminderStatus = "Scheduling…"
        reminderSet.command = [root.script, "reminder", "set", String(mins), text]
        restartProc(reminderSet)
    }

    Process {
        id: brightnessGet
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = (text || "").trim().split("|")
                if (parts.length >= 2) {
                    var cur = parseInt(parts[0])
                    var max = parseInt(parts[1])
                    if (!isNaN(cur)) root.brightnessCur = cur
                    if (!isNaN(max) && max > 0) root.brightnessMax = max
                }
            }
        }
    }

    Process {
        id: brightnessSet
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = (text || "").trim().split("|")
                if (parts.length >= 2) {
                    var cur = parseInt(parts[0])
                    var max = parseInt(parts[1])
                    if (!isNaN(cur)) root.brightnessCur = cur
                    if (!isNaN(max) && max > 0) root.brightnessMax = max
                }
            }
        }
    }

    Process {
        id: fontGet
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt((text || "").trim())
                if (!isNaN(n) && n >= 10 && n <= 20) {
                    root.textSize = n
                    C.SettingsStore.syncFontSize(n)
                }
            }
        }
    }

    Process {
        id: scaleGet
        stdout: StdioCollector {
            onStreamFinished: {
                var s = parseFloat((text || "").trim())
                if (!isNaN(s) && s > 0) {
                    root.outputScale = s
                    C.SettingsStore.syncOutputScale(s)
                }
            }
        }
    }

    Process {
        id: wallpaperGet
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpaperName = (text || "").trim()
            }
        }
    }

    Process {
        id: themeColorsGet
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse((text || "[]").trim())
                    root.themeColors = Array.isArray(arr) ? arr : []
                } catch (e) {
                    root.themeColors = []
                }
            }
        }
    }

    Process {
        id: themeApply
        stdout: StdioCollector {
            onStreamFinished: {
                root.themeBusy = false
                try {
                    var arr = JSON.parse((text || "[]").trim())
                    root.themeColors = Array.isArray(arr) ? arr : []
                } catch (e) {
                    themeColorsGet.command = [root.script, "theme", "colors"]
                    restartProc(themeColorsGet)
                }
                wallpaperGet.command = [root.script, "wallpaper", "name"]
                restartProc(wallpaperGet)
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.themeBusy = false
            }
        }
    }

    Process { id: wallpaperOpen }

    Process {
        id: reminderSet
        stdout: StdioCollector {
            onStreamFinished: {
                var line = (text || "").trim().split("\n")[0]
                var parts = line.split("|")
                if (parts.length >= 3 && parts[0] === "ok") {
                    var at = parts[1]
                    var unit = parts.length >= 4 ? parts[3] : (parts[2] + " minutes")
                    root.reminderStatus = "Set — toast at " + at + " (" + unit + ")"
                } else if (line.length) {
                    root.reminderStatus = line
                } else {
                    root.reminderStatus = "Scheduled"
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var err = (text || "").trim()
                if (err.length)
                    root.reminderStatus = err.split("\n")[0]
            }
        }
    }

    Process {
        id: voxtypeOnce
        stdout: StdioCollector {
            onStreamFinished: root.parseVoxtypeJson(text)
        }
    }

    Process {
        id: voxtypeDaemonGet
        stdout: StdioCollector {
            onStreamFinished: {
                var st = (text || "").trim().split("\n")[0]
                if (st.length)
                    root.voxtypeDaemon = st
            }
        }
    }

    Process {
        id: voxtypeDaemonToggle
        stdout: StdioCollector {
            onStreamFinished: {
                var st = (text || "").trim().split("\n")[0]
                if (st.length)
                    root.voxtypeDaemon = st
                voxtypeRefreshTimer.restart()
            }
        }
    }

    Process { id: voxtypeRecord }
    Process { id: voxtypeConfig }

    Timer {
        id: voxtypeRefreshTimer
        interval: 600
        repeat: false
        onTriggered: root.refreshVoxtype()
    }

    // Poll voxtype while settings panel is open
    Timer {
        interval: 1500
        running: root.visible
        repeat: true
        onTriggered: root.refreshVoxtype()
    }

    Process {
        id: colorPicker
        stdout: StdioCollector {
            onStreamFinished: {
                var line = (text || "").trim().split("\n")[0]
                // Script returns started|<tool> immediately after backgrounding the picker
                if (line.indexOf("started|") === 0 || line.indexOf("started") === 0)
                    root.dismissed()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var err = (text || "").trim()
                if (err.length)
                    console.log("colorpicker:", err)
            }
        }
    }

    Process {
        id: colorPickRead
        stdout: StdioCollector {
            onStreamFinished: {
                var hex = (text || "").trim().split("\n")[0]
                if (hex && hex.charAt(0) === "#")
                    root.lastPickedColor = hex
                else if (hex && /^[0-9A-Fa-f]{6}$/.test(hex))
                    root.lastPickedColor = "#" + hex
            }
        }
    }

    // Keep brightness in sync with hardware keys while panel is open
    Process {
        running: root.visible
        command: ["udevadm", "monitor", "--subsystem-match=backlight"]
        stdout: SplitParser {
            splitMarker: "UDEV"
            onRead: function() {
                brightnessGet.command = [root.script, "brightness", "get"]
                restartProc(brightnessGet)
            }
        }
    }

    Rectangle {
        id: panelBox
        anchors.fill: parent
        color: C.Theme.tooltipBg
        border.color: "#33ffcc00"
        border.width: 1
        radius: 4

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            contentWidth: width
            contentHeight: col.implicitHeight + 16
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            Column {
                id: col
                width: flick.width
                spacing: 12

            // Header
            RowLayout {
                width: parent.width
                spacing: 8
                Text {
                    text: "󰒓"
                    color: C.Theme.yellow
                    font.pixelSize: C.Theme.fontIcon
                }
                Text {
                    text: "Settings"
                    color: C.Theme.text
                    font.pixelSize: C.Theme.fontMd
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Brightness
            Column {
                width: parent.width
                spacing: 8

                RowLayout {
                    width: parent.width
                    Text {
                        text: "BRIGHTNESS"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(root.brightnessPct * 100) + "%"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontXs
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10
                    Text {
                        text: "󰃠"
                        color: C.Theme.yellow
                        font.pixelSize: C.Theme.fontIcon
                    }
                    Item {
                        id: brightTrack
                        Layout.fillWidth: true
                        height: 18

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 3
                            radius: 1
                            color: "#44ffffff"
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, parent.width * root.brightnessPct)
                            height: 3
                            radius: 1
                            color: C.Theme.yellow
                        }
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: "#ffffff"
                            border.color: C.Theme.yellow
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * root.brightnessPct - width / 2))
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function apply(mx) {
                                var pct = Math.max(0, Math.min(1, mx / width)) * 100
                                root.setBrightnessPct(pct)
                            }
                            onPressed: function(mouse) { apply(mouse.x) }
                            onPositionChanged: function(mouse) {
                                if (pressed)
                                    apply(mouse.x)
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Text size
            Column {
                width: parent.width
                spacing: 8

                RowLayout {
                    width: parent.width
                    Text {
                        text: "TEXT SIZE"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.textSize + "px"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontXs
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Item {
                    id: fontTrack
                    width: parent.width
                    height: 22

                    readonly property int minPx: 10
                    readonly property int maxPx: 20
                    readonly property int steps: maxPx - minPx
                    readonly property real stepW: width / steps

                    // Tick marks
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        spacing: 0
                        Repeater {
                            model: fontTrack.steps + 1
                            Item {
                                width: index < fontTrack.steps ? fontTrack.stepW : 0
                                height: 12
                                Rectangle {
                                    width: 1
                                    height: 8
                                    color: "#55ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 2
                        color: "#44ffffff"
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ((root.textSize - fontTrack.minPx) / fontTrack.steps) * parent.width
                        height: 2
                        color: C.Theme.yellow
                    }
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#ffffff"
                        border.color: C.Theme.yellow
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width,
                            ((root.textSize - fontTrack.minPx) / fontTrack.steps) * parent.width - width / 2))
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function apply(mx) {
                            var t = Math.max(0, Math.min(1, mx / width))
                            var px = Math.round(fontTrack.minPx + t * fontTrack.steps)
                            root.setTextSize(px)
                        }
                        onPressed: function(mouse) { apply(mouse.x) }
                        onPositionChanged: function(mouse) {
                            if (pressed)
                                apply(mouse.x)
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Scale
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "SCALE"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    font.bold: true
                }

                Flow {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.scaleOptions
                        delegate: Rectangle {
                            required property var modelData
                            width: 48
                            height: 28
                            radius: 2
                            readonly property bool active: Math.abs(root.outputScale - modelData.value) < 0.05
                            color: active ? "#33ffcc00" : (scaleHover.containsMouse ? "#22ffffff" : "transparent")
                            border.width: 1
                            border.color: active ? C.Theme.yellow : "#44ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: parent.active ? C.Theme.yellow : C.Theme.text
                                font.pixelSize: C.Theme.fontXs
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: scaleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setScale(modelData.value)
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Autohide toggle
            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "Statusbar Autohide"
                    color: C.Theme.text
                    font.pixelSize: C.Theme.fontSm
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: autoSwitch
                    width: 38
                    height: 20
                    radius: 10
                    color: root.barAutohide ? C.Theme.yellow : "#33ffffff"
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        y: 3
                        x: root.barAutohide ? parent.width - 17 : 3
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setAutohide(!root.barAutohide)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Wallpaper
            Rectangle {
                id: wallpaperRow
                width: parent.width
                height: 36
                radius: 2
                color: wallHover.containsMouse ? "#18ffffff" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8
                    Text {
                        text: "Wallpaper"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontSm
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.wallpaperName.length ? root.wallpaperName : "—"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 140
                    }
                    Text {
                        text: "󰍹"
                        color: C.Theme.yellow
                        font.pixelSize: C.Theme.fontIcon
                    }
                }
                MouseArea {
                    id: wallHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openWallpaper()
                    onEntered: C.Tooltip.show(wallpaperRow, "Open wallpaper picker (Mod+w)")
                    onExited: C.Tooltip.hide()
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Theme
            Column {
                width: parent.width
                spacing: 8

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "Theme"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontSm
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        id: themeApplyBtn
                        width: 28
                        height: 28
                        radius: 2
                        color: themeBtnHover.containsMouse ? "#22ffffff" : "transparent"
                        opacity: root.themeBusy ? 0.5 : 1
                        Text {
                            anchors.centerIn: parent
                            text: root.themeBusy ? "󰔟" : "󰑓"
                            color: C.Theme.yellow
                            font.pixelSize: C.Theme.fontIcon
                        }
                        MouseArea {
                            id: themeBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.themeBusy
                            onClicked: root.applyTheme()
                            onEntered: C.Tooltip.show(themeApplyBtn, "Apply pywal theme from wallpaper")
                            onExited: C.Tooltip.hide()
                        }
                    }
                    Text {
                        text: "󰒓"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontMd
                    }
                }

                // Palette strip
                Item {
                    width: parent.width
                    height: 22
                    visible: root.themeColors.length > 0

                    Row {
                        anchors.fill: parent
                        spacing: 2
                        Repeater {
                            model: Math.min(root.themeColors.length, 16)
                            Rectangle {
                                required property int index
                                width: Math.max(8, (parent.width - 2 * 15) / Math.min(root.themeColors.length, 16))
                                height: 22
                                radius: 2
                                color: root.themeColors[index] || "#333333"
                                border.color: "#22ffffff"
                                border.width: 1
                            }
                        }
                    }
                }

                Text {
                    visible: root.themeColors.length === 0
                    width: parent.width
                    text: "No pywal palette yet — set a wallpaper, then apply"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: root.wallpaperName.length > 0
                    width: parent.width
                    text: root.wallpaperName
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    elide: Text.ElideMiddle
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Set Reminders
            Column {
                id: reminderSection
                width: parent.width
                spacing: 8

                Rectangle {
                    id: reminderHeader
                    width: parent.width
                    height: 36
                    radius: 2
                    color: remHeaderHover.containsMouse ? "#18ffffff" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        Text {
                            text: "󰀠"
                            color: C.Theme.yellow
                            font.pixelSize: C.Theme.fontIcon
                        }
                        Text {
                            text: "Set Reminders"
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.reminderExpanded ? "󰅃" : "󰅀"
                            color: C.Theme.textMuted
                            font.pixelSize: C.Theme.fontMd
                        }
                    }
                    MouseArea {
                        id: remHeaderHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.reminderExpanded = !root.reminderExpanded
                            if (root.reminderExpanded)
                                scrollReminder.restart()
                        }
                        onEntered: C.Tooltip.show(reminderHeader, "Schedule a toast reminder")
                        onExited: C.Tooltip.hide()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.reminderExpanded

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 2
                        color: "#18ffffff"
                        border.color: reminderInput.activeFocus ? C.Theme.yellow : "#33ffffff"
                        border.width: 1

                        TextInput {
                            id: reminderInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                            clip: true
                            selectByMouse: true
                            text: root.reminderText
                            onTextChanged: root.reminderText = text
                            Keys.onReturnPressed: root.setReminder()
                            Keys.onEnterPressed: root.setReminder()
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: "What should I remind you?"
                            color: C.Theme.textMuted
                            font.pixelSize: C.Theme.fontSm
                            visible: !reminderInput.text.length && !reminderInput.activeFocus
                        }
                    }

                    Item {
                        id: presetRow
                        width: parent.width
                        height: Math.max(24, presetFlow.implicitHeight)

                        Text {
                            id: inLabel
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "In"
                            color: C.Theme.textMuted
                            font.pixelSize: C.Theme.fontXs
                        }

                        Flow {
                            id: presetFlow
                            anchors.left: inLabel.right
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(40, parent.width - inLabel.width - minutesField.width - 12)
                            spacing: 4

                            Repeater {
                                model: root.reminderPresets
                                delegate: Rectangle {
                                    required property int modelData
                                    width: Math.max(28, presetLabel.implicitWidth + 10)
                                    height: 24
                                    radius: 2
                                    readonly property bool active: root.reminderMinutes === modelData
                                    color: active ? "#33ffcc00" : (presetHover.containsMouse ? "#22ffffff" : "transparent")
                                    border.width: 1
                                    border.color: active ? C.Theme.yellow : "#44ffffff"

                                    Text {
                                        id: presetLabel
                                        anchors.centerIn: parent
                                        text: modelData === 60 ? "1h" : (modelData + "m")
                                        color: parent.active ? C.Theme.yellow : C.Theme.text
                                        font.pixelSize: C.Theme.fontXs
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    MouseArea {
                                        id: presetHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.reminderMinutes = modelData
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: minutesField
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 24
                            radius: 2
                            color: "#18ffffff"
                            border.color: "#44ffffff"
                            border.width: 1
                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 4
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: C.Theme.text
                                font.pixelSize: C.Theme.fontXs
                                font.family: "JetBrainsMono Nerd Font"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 1; top: 10080 }
                                text: String(root.reminderMinutes)
                                onEditingFinished: {
                                    var n = parseInt(text)
                                    if (!isNaN(n) && n >= 1)
                                        root.reminderMinutes = n
                                    else
                                        text = String(root.reminderMinutes)
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: root.reminderStatus.length ? root.reminderStatus : "Toast after the delay via swaync"
                            color: C.Theme.textMuted
                            font.pixelSize: C.Theme.fontXs
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: reminderSetBtn
                            width: setBtnLabel.implicitWidth + 16
                            height: 28
                            radius: 2
                            color: setBtnHover.containsMouse ? "#44ffcc00" : "#33ffcc00"
                            border.color: C.Theme.yellow
                            border.width: 1

                            Text {
                                id: setBtnLabel
                                anchors.centerIn: parent
                                text: "Set"
                                color: C.Theme.yellow
                                font.pixelSize: C.Theme.fontSm
                                font.bold: true
                            }
                            MouseArea {
                                id: setBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setReminder()
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Whisper / Voxtype
            Column {
                width: parent.width
                spacing: 8

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "󰚩"
                        color: {
                            if (root.voxtypeClass === "recording")
                                return C.Theme.red
                            if (root.voxtypeClass === "transcribing")
                                return C.Theme.yellow
                            if (root.voxtypeDaemon === "running")
                                return C.Theme.yellow
                            return C.Theme.textMuted
                        }
                        font.pixelSize: C.Theme.fontIcon
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Whisper"
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                        }
                        Text {
                            text: {
                                var bits = [root.voxtypeStateLabel()]
                                if (root.voxtypeModel.length)
                                    bits.push(root.voxtypeModel)
                                if (root.voxtypeBackend.length)
                                    bits.push(root.voxtypeBackend)
                                return bits.join(" · ")
                            }
                            color: C.Theme.textMuted
                            font.pixelSize: C.Theme.fontXs
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                    Rectangle {
                        id: voxCfgBtn
                        width: 28
                        height: 28
                        radius: 2
                        color: voxCfgHover.containsMouse ? "#22ffffff" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            color: C.Theme.yellow
                            font.pixelSize: C.Theme.fontMd
                        }
                        MouseArea {
                            id: voxCfgHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openVoxtypeConfig()
                            onEntered: C.Tooltip.show(voxCfgBtn, "Open Voxtype TUI / setup")
                            onExited: C.Tooltip.hide()
                        }
                    }
                    Rectangle {
                        id: voxDaemonSwitch
                        width: 38
                        height: 20
                        radius: 10
                        color: (root.voxtypeDaemon === "running" || root.voxtypeDaemon === "starting")
                               ? C.Theme.yellow : "#33ffffff"
                        opacity: root.voxtypeAvailable ? 1 : 0.4
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            y: 3
                            x: (root.voxtypeDaemon === "running" || root.voxtypeDaemon === "starting")
                               ? parent.width - 17 : 3
                            color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.voxtypeAvailable
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleVoxtypeDaemon()
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 6
                    visible: root.voxtypeAvailable

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 2
                        color: recHover.containsMouse ? "#33ff5555" : "#22ffffff"
                        border.color: root.voxtypeClass === "recording" ? C.Theme.red : "#44ffffff"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.voxtypeClass === "recording" ? "Stop recording" : "Toggle record"
                            color: root.voxtypeClass === "recording" ? C.Theme.red : C.Theme.text
                            font.pixelSize: C.Theme.fontXs
                        }
                        MouseArea {
                            id: recHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleVoxtypeRecord()
                            onEntered: C.Tooltip.show(parent, "Or hold Super+v (push-to-talk)")
                            onExited: C.Tooltip.hide()
                        }
                    }
                }

                Text {
                    visible: !root.voxtypeAvailable
                    width: parent.width
                    text: "Install: paru -S voxtype-bin wtype && voxtype setup systemd"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Color picker
            Rectangle {
                id: pickerRow
                width: parent.width
                height: 36
                radius: 2
                color: pickHover.containsMouse ? "#18ffffff" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8
                    Text {
                        text: "Color Picker"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontSm
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: root.lastPickedColor.length > 0
                        width: 16
                        height: 16
                        radius: 2
                        color: root.lastPickedColor.length ? root.lastPickedColor : "transparent"
                        border.color: "#66ffffff"
                        border.width: 1
                    }
                    Text {
                        visible: root.lastPickedColor.length > 0
                        text: root.lastPickedColor
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "󰈊"
                        color: C.Theme.yellow
                        font.pixelSize: C.Theme.fontIcon
                    }
                }
                MouseArea {
                    id: pickHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runColorPicker()
                    onEntered: C.Tooltip.show(pickerRow, "Pick a color (Mod+Shift+p) — wl-color-picker")
                    onExited: C.Tooltip.hide()
                }
            }
            } // Column
        } // flick
    } // panelBox
}
