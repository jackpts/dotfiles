import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../components" as C

PopupWindow {
    id: root
    property Item anchorItem: null
    property bool menuOpen: false
    property string kind: "disc"
    property string ssid: ""
    property string iface: ""
    property string ip: "—"
    property string gateway: ""
    property string downRate: "—"
    property string upRate: "—"
    property real rxBytes: 0
    property real txBytes: 0
    property int maxHeight: 700
    property bool vpnActive: false
    property string vpnName: ""
    property string vpnIface: ""
    property string script: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/jackbar/modules/network-panel.sh"

    property bool radioOn: true
    property bool band5ghz: false
    property string dnsMode: "dhcp"
    property string dnsCustom: ""
    property string pingRtt: "—"
    property string pingLoss: "—"
    property string connectingSsid: ""
    property string passwordSsid: ""
    property string passwordBssid: ""
    property string passwordSecurity: ""
    property string passwordDraft: ""
    property string _listRaw: ""
    property var pingSamples: []
    property string _pendingPass: ""

    signal dismissed()

    visible: menuOpen
    grabFocus: true
    color: "transparent"
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.SlideX
    anchor.margins.top: 6
    implicitWidth: 400
    // Keep this short so it always fits under the bar. Networks scroll inside.
    implicitHeight: Math.min(480, Math.max(360, maxHeight))

    onVisibleChanged: {
        if (visible) {
            pingSamples = []
            passwordSsid = ""
            passwordDraft = ""
            refreshAll(true)
            pingTimer.start()
            listTimer.start()
        } else {
            pingTimer.stop()
            listTimer.stop()
            dismissed()
        }
    }

    function headerTitle() {
        if (kind === "wifi")
            return ssid && ssid.length ? ssid : "Wi-Fi"
        if (kind === "eth")
            return iface && iface.length ? iface : "Ethernet"
        return "Disconnected"
    }

    function headerSub() {
        if (kind === "wifi" && ssid && ssid.length)
            return "Connected"
        if (kind === "eth")
            return "Ethernet"
        if (!radioOn)
            return "Wi-Fi off"
        return "Not connected"
    }

    function fmtGb(n) {
        var v = Number(n) || 0
        if (v < 0)
            v += 4294967296
        return (v / 1073741824).toFixed(1) + " GB"
    }

    function signalIcon(sig) {
        if (sig >= 80) return "󰤨"
        if (sig >= 60) return "󰤥"
        if (sig >= 40) return "󰤢"
        if (sig >= 20) return "󰤟"
        return "󰤯"
    }

    function restartProc(p) {
        p.running = false
        p.running = true
    }

    function refreshAll(rescan) {
        radioGet.running = false
        radioGet.running = true
        dnsGet.running = false
        dnsGet.running = true
        bandGet.running = false
        bandGet.running = true
        refreshList(rescan)
        pingOnce.running = false
        pingOnce.running = true
    }

    function refreshList(rescan) {
        listProc.command = rescan ? [root.script, "wifi-list", "rescan"] : [root.script, "wifi-list"]
        listProc.running = false
        listProc.running = true
    }

    function applyList(text) {
        root._listRaw = text || ""
        knownModel.clear()
        otherModel.clear()
        var lines = root._listRaw.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (!line || !line.length)
                continue
            var p = line.split("\t")
            if (p.length < 6)
                continue
            var freq = parseInt(p[3]) || 0
            if (root.band5ghz && freq > 0 && freq < 5000)
                continue
            var row = {
                "inUse": p[0] === "1",
                "ssid": p[1],
                "signal": parseInt(p[2]) || 0,
                "freq": freq,
                "security": p[4] || "",
                "saved": p[5] === "1",
                "bssid": p.length > 6 ? p[6] : ""
            }
            if (row.saved || row.inUse)
                knownModel.append(row)
            else
                otherModel.append(row)
        }
    }

    function setRadio(on) {
        radioSet.command = [root.script, "wifi-radio", on ? "on" : "off"]
        restartProc(radioSet)
    }

    function setBand(on) {
        root.band5ghz = on
        bandSet.command = [root.script, "band-set", on ? "1" : "0"]
        restartProc(bandSet)
        applyList(root._listRaw)
    }

    function setDns(mode) {
        if (mode === "custom") {
            root.dnsMode = "custom"
            return
        }
        dnsSetProc.command = [root.script, "dns-set", mode]
        restartProc(dnsSetProc)
    }

    function applyCustomDns() {
        var servers = (customDnsInput.text || "").replace(/,/g, " ").trim()
        if (!servers.length)
            return
        dnsSetProc.command = [root.script, "dns-set", "custom"].concat(servers.split(/\s+/))
        restartProc(dnsSetProc)
    }

    function connectNet(row) {
        if (!row || !row.ssid || connectingSsid.length)
            return
        if (row.inUse)
            return
        if (!row.saved && row.security && row.security.length) {
            passwordSsid = row.ssid
            passwordBssid = row.bssid || ""
            passwordSecurity = row.security
            passwordDraft = ""
            return
        }
        startConnect(row.ssid, row.saved ? "1" : "0", row.security || "", row.bssid || "", "")
    }

    function startConnect(ssid, saved, security, bssid, pass) {
        connectingSsid = ssid
        _pendingPass = pass || ""
        connectProc.stdinEnabled = !!(pass && pass.length)
        var args = [root.script, "wifi-connect", ssid, saved, security]
        if (bssid && bssid.length)
            args.push(bssid)
        connectProc.command = args
        connectProc.running = false
        connectProc.running = true
    }

    function submitPassword() {
        if (!passwordSsid.length || !passwordDraft.length)
            return
        startConnect(passwordSsid, "0", passwordSecurity, passwordBssid, passwordDraft)
        passwordSsid = ""
        passwordDraft = ""
    }

    function runSpeedtest() {
        speedProc.command = ["kitty", "--class", "jackbar-speedtest", "-e", "bash", "-lc", "speedtest-cli; echo; echo 'Press any key to close'; read -n 1 -s -r"]
        speedProc.startDetached()
    }

    function pushPing(rtt, loss) {
        pingRtt = rtt && rtt.length ? rtt : "—"
        var missed = (pingRtt === "—" || parseFloat(loss) >= 100)
        var samples = pingSamples.slice()
        samples.push(missed ? 1 : 0)
        if (samples.length > 5)
            samples = samples.slice(samples.length - 5)
        pingSamples = samples
        var bad = 0
        for (var i = 0; i < samples.length; i++)
            bad += samples[i]
        pingLoss = samples.length ? (Math.round(100 * bad / samples.length) + "%") : "—"
        if (pingRtt !== "—")
            pingRtt = pingRtt + " ms"
    }

    ListModel { id: knownModel }
    ListModel { id: otherModel }

    Process {
        id: listProc
        stdout: StdioCollector { onStreamFinished: root.applyList(this.text) }
    }
    Process {
        id: radioGet
        command: [root.script, "wifi-radio", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.radioOn = this.text.trim() === "on"
        }
    }
    Process {
        id: radioSet
        stdout: StdioCollector {
            onStreamFinished: {
                root.radioOn = this.text.trim() === "on"
                root.refreshList(true)
            }
        }
    }
    Process {
        id: dnsGet
        command: [root.script, "dns-get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (t.indexOf("custom|") === 0) {
                    root.dnsMode = "custom"
                    root.dnsCustom = t.slice(7)
                } else {
                    root.dnsMode = t.length ? t : "dhcp"
                    if (root.dnsMode !== "custom")
                        root.dnsCustom = ""
                }
            }
        }
    }
    Process {
        id: dnsSetProc
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (t.indexOf("custom|") === 0) {
                    root.dnsMode = "custom"
                    root.dnsCustom = t.slice(7)
                } else if (t.length) {
                    root.dnsMode = t
                }
            }
        }
        onExited: function(code) {
            if (code !== 0)
                notify.command = ["notify-send", "-u", "normal", "Network", "Could not change DNS"]
            if (code !== 0)
                notify.running = true
        }
    }
    Process {
        id: bandGet
        command: [root.script, "band-get"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.band5ghz = this.text.trim() === "1"
                if (root._listRaw.length)
                    root.applyList(root._listRaw)
            }
        }
    }
    Process { id: bandSet }
    Process {
        id: pingOnce
        command: [root.script, "ping-once"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split("|")
                root.pushPing(p.length ? p[0] : "—", p.length > 1 ? p[1] : "100")
            }
        }
    }
    Process {
        id: connectProc
        stdinEnabled: false
        onStarted: {
            if (root._pendingPass && root._pendingPass.length) {
                connectProc.write(root._pendingPass + "\n")
                connectProc.stdinEnabled = false
            }
        }
        onExited: function(code) {
            var ssid = root.connectingSsid
            root.connectingSsid = ""
            root._pendingPass = ""
            if (code === 0) {
                root.refreshList(true)
                return
            }
            notify.command = ["notify-send", "-u", "normal", "Network", "Failed to connect to " + ssid]
            notify.running = true
        }
    }
    Process { id: notify }
    Process { id: speedProc }

    Timer {
        id: pingTimer
        interval: 4000
        running: false
        repeat: true
        onTriggered: {
            pingOnce.running = false
            pingOnce.running = true
        }
    }
    Timer {
        id: listTimer
        interval: 10000
        running: false
        repeat: true
        onTriggered: root.refreshList(false)
    }

    Rectangle {
        id: box
        anchors.fill: parent
        color: C.Theme.tooltipBg

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header
            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: root.kind === "eth" ? "󰈀" : (root.radioOn ? "󰤨" : "󰤭")
                    color: C.Theme.networkWifi
                    font.pixelSize: C.Theme.fontIconLg
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: root.headerTitle()
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontMd
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: root.headerSub()
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                    }
                }

                Rectangle {
                    id: speedBtn
                    width: 28
                    height: 28
                    radius: 2
                    color: speedHover.containsMouse ? "#22ffffff" : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰓅"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontIcon
                    }
                    MouseArea {
                        id: speedHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runSpeedtest()
                        onEntered: C.Tooltip.show(speedBtn, "Run a speed test")
                        onExited: C.Tooltip.hide()
                    }
                }

                Rectangle {
                    id: radioSwitch
                    width: 38
                    height: 20
                    radius: 10
                    color: root.radioOn ? C.Theme.networkWifi : "#33ffffff"
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        y: 3
                        x: root.radioOn ? parent.width - 17 : 3
                        color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.setRadio(!root.radioOn)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // Stats grid
            RowLayout {
                width: parent.width
                spacing: 16

                Column {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 6
                    RowLayout {
                        width: parent.width
                        Text { text: "Ping"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.pingRtt; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "Receiving"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.downRate && root.downRate.length ? root.downRate : "—"; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "Downloaded"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.fmtGb(root.rxBytes); color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "IP address"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.ip && root.ip.length ? root.ip : "—"; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 6
                    RowLayout {
                        width: parent.width
                        Text { text: "Packet loss"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.pingLoss; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "Sending"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.upRate && root.upRate.length ? root.upRate : "—"; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "Uploaded"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.fmtGb(root.txBytes); color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "Gateway"; color: C.Theme.textMuted; font.pixelSize: C.Theme.fontXs }
                        Item { Layout.fillWidth: true }
                        Text { text: root.gateway && root.gateway.length ? root.gateway : "—"; color: C.Theme.text; font.pixelSize: C.Theme.fontSm; font.family: "JetBrainsMono Nerd Font" }
                    }
                }
            }

            Text {
                visible: root.vpnActive
                width: parent.width
                text: "VPN: " + (root.vpnName && root.vpnName.length ? root.vpnName : (root.vpnIface || "Active"))
                color: C.Theme.networkWifi
                font.pixelSize: C.Theme.fontXs
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            // 5 GHz filter
            RowLayout {
                width: parent.width
                visible: root.radioOn
                Text {
                    text: "WI-FI BAND" + (root.band5ghz ? ": 5GHZ" : "")
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: "5 GHz only"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                }
                Rectangle {
                    width: 38
                    height: 20
                    radius: 10
                    color: root.band5ghz ? C.Theme.networkWifi : "#33ffffff"
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        y: 3
                        x: root.band5ghz ? parent.width - 17 : 3
                        color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.setBand(!root.band5ghz)
                    }
                }
            }

            Rectangle { visible: root.radioOn; width: parent.width; height: 1; color: "#22ffffff" }

            // DNS
            Text {
                text: "DNS PROVIDER"
                color: C.Theme.textMuted
                font.pixelSize: C.Theme.fontXs
                font.bold: true
            }

            Row {
                spacing: 6
                Repeater {
                    model: [
                        { id: "dhcp", label: "DHCP" },
                        { id: "cloudflare", label: "Cloudflare" },
                        { id: "google", label: "Google" },
                        { id: "custom", label: "Custom" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 18) / 4
                        height: 28
                        radius: 2
                        readonly property bool active: root.dnsMode === modelData.id
                        color: active ? "#55cc88ff" : (dnsHover.containsMouse ? "#22ffffff" : "#18ffffff")
                        border.width: active ? 1 : 0
                        border.color: C.Theme.networkWifi
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.active ? C.Theme.text : C.Theme.textMuted
                            font.pixelSize: C.Theme.fontXs
                        }
                        MouseArea {
                            id: dnsHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.setDns(modelData.id)
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                visible: root.dnsMode === "custom"
                spacing: 6
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: "#18ffffff"
                    TextInput {
                        id: customDnsInput
                        anchors.fill: parent
                        anchors.margins: 6
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontSm
                        text: root.dnsCustom
                        selectedTextColor: C.Theme.tooltipBg
                        selectionColor: C.Theme.networkWifi
                        Keys.onReturnPressed: root.applyCustomDns()
                    }
                }
                Rectangle {
                    width: 56
                    height: 28
                    color: "#33cc88ff"
                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: C.Theme.text
                        font.pixelSize: C.Theme.fontXs
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.applyCustomDns()
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#22ffffff" }

            Flickable {
                id: netsFlick
                width: parent.width
                height: Math.max(120, col.height - y - (root.passwordSsid.length > 0 ? 70 : 0))
                clip: true
                contentWidth: width
                contentHeight: netsCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: netsCol
                    width: parent.width
                    spacing: 6

                    Text {
                        visible: root.radioOn
                        text: "KNOWN NETWORKS"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        font.bold: true
                    }

                    Repeater {
                        model: knownModel
                        delegate: netRow
                    }
                    Text {
                        visible: root.radioOn && knownModel.count === 0
                        text: "None in range"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                    }

                    Text {
                        visible: root.radioOn
                        text: "OTHER NETWORKS"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                        font.bold: true
                    }

                    Repeater {
                        model: otherModel
                        delegate: netRow
                    }
                    Text {
                        visible: root.radioOn && otherModel.count === 0
                        text: "None in range"
                        color: C.Theme.textMuted
                        font.pixelSize: C.Theme.fontXs
                    }
                }
            }

            // Password prompt
            Column {
                width: parent.width
                visible: root.passwordSsid.length > 0
                spacing: 6
                onVisibleChanged: {
                    if (visible)
                        passInput.forceActiveFocus()
                }
                Text {
                    text: "Password for " + root.passwordSsid
                    color: C.Theme.text
                    font.pixelSize: C.Theme.fontXs
                    elide: Text.ElideRight
                    width: parent.width
                }
                RowLayout {
                    width: parent.width
                    spacing: 6
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: "#18ffffff"
                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.margins: 6
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontSm
                            echoMode: TextInput.Password
                            text: root.passwordDraft
                            onTextChanged: root.passwordDraft = text
                            Keys.onReturnPressed: root.submitPassword()
                        }
                    }
                    Rectangle {
                        width: 64
                        height: 28
                        color: "#33cc88ff"
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: C.Theme.text
                            font.pixelSize: C.Theme.fontXs
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.submitPassword()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: netRow
        Rectangle {
            required property string ssid
            required property int signal
            required property bool inUse
            required property bool saved
            required property string security
            required property string bssid
            required property int freq
            width: netsCol.width
            height: 34
            color: inUse ? "#22ffffff" : (rowHover.containsMouse ? "#14ffffff" : "transparent")
            opacity: root.connectingSsid === ssid ? 0.6 : 1

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.connectNet({
                    "ssid": ssid,
                    "signal": signal,
                    "inUse": inUse,
                    "saved": saved,
                    "security": security,
                    "bssid": bssid
                })
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 8
                Text {
                    text: root.signalIcon(signal)
                    color: C.Theme.networkWifi
                    font.pixelSize: C.Theme.fontMd
                }
                Text {
                    text: ssid
                    color: C.Theme.text
                    font.pixelSize: C.Theme.fontSm
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: inUse
                    text: "Connected"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontXs
                }
                Text {
                    visible: root.connectingSsid === ssid
                    text: "Connecting…"
                    color: C.Theme.networkWifi
                    font.pixelSize: C.Theme.fontXs
                }
                Text {
                    visible: security.length > 0
                    text: "󰌾"
                    color: C.Theme.textMuted
                    font.pixelSize: C.Theme.fontSm
                }
            }
        }
    }
}
