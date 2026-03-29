import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    // Width follows content (icon/text) instead of being fixed
    width: Math.max(indicatorText.implicitWidth + 8, 40)
    height: C.Theme.panelHeight
    property string kind: "disc" // wifi | eth | disc
    property string ssid: ""
    property int signal: 0
    property string signalDbm: ""
    property string frequency: ""
    property string ip: "—"
    property string iface: ""
    property string gateway: ""
    property string publicIp: ""
    property int rxBytes: 0
    property int txBytes: 0
    property int _lastRxBytes: 0
    property int _lastTxBytes: 0
    property double _lastSampleMs: 0
    property string downRate: ""
    property string upRate: ""

    function icon() {
        if (kind === "wifi") return "󰤨";
        if (kind === "eth") return "󰈀";
        return "󰤭";
    }

    function buildTooltip() {
        var lines = []
        var down = (root.downRate && root.downRate.length) ? root.downRate : "—"
        var up = (root.upRate && root.upRate.length) ? root.upRate : "—"
        if (root.kind === "wifi") {
            lines.push("Network: " + (root.ssid || "Unknown"))
            if (root.signalDbm && root.signalDbm.length && root.signal) {
                lines.push("Signal: " + root.signalDbm + "dBm (" + root.signal + "%)")
            } else if (root.signal) {
                lines.push("Signal: " + root.signal + "%")
            }
            if (root.frequency && root.frequency.length) lines.push("Frequency: " + root.frequency + "MHz")
            if (root.iface && root.iface.length) lines.push("Interface: " + root.iface)
            if (root.ip && root.ip.length) lines.push("Local IP: " + root.ip)
            if (root.gateway && root.gateway.length) lines.push("Gateway: " + root.gateway)
            if (root.publicIp && root.publicIp.length) lines.push("Public IP: " + root.publicIp)
            lines.push("󰇚 " + down)
            lines.push("󰕒 " + up)
        } else if (root.kind === "eth") {
            if (root.iface && root.iface.length) lines.push("Interface: " + root.iface)
            if (root.ip && root.ip.length) lines.push("Local IP: " + root.ip)
            if (root.gateway && root.gateway.length) lines.push("Gateway: " + root.gateway)
            if (root.publicIp && root.publicIp.length) lines.push("Public IP: " + root.publicIp)
            lines.push("󰇚 " + down)
            lines.push("󰕒 " + up)
        } else {
            lines.push("Disconnected")
        }
        // Use HTML line breaks so tooltip renders each entry on its own line
        return lines.join("<br/>")
    }

    Process {
        id: proc
        command: ["/home/jacky/dotfiles/.config/quickshell/jackbar/modules/network-detect.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|")
                if (parts.length >= 1 && parts[0].length) root.kind = parts[0]
                if (parts.length >= 2) root.ssid = parts[1]
                if (parts.length >= 3 && parts[2].length) root.signal = parseInt(parts[2])
                if (parts.length >= 4) root.signalDbm = parts[3]
                if (parts.length >= 5) root.frequency = parts[4]
                if (parts.length >= 6) root.ip = parts[5].length ? parts[5] : "—"
                if (parts.length >= 7) root.iface = parts[6]
                if (parts.length >= 8) root.gateway = parts[7]
                if (parts.length >= 9) {
                    var rt = parts[8].split(":")
                    if (rt.length === 2) {
                        root.rxBytes = parseInt(rt[0])
                        root.txBytes = parseInt(rt[1])
                        var now = Date.now()
                        if (root._lastSampleMs > 0) {
                            var dt = Math.max(1, now - root._lastSampleMs) / 1000.0
                            var dr = Math.max(0, root.rxBytes - root._lastRxBytes) / dt
                            var dtb = Math.max(0, root.txBytes - root._lastTxBytes) / dt
                            function fmt(bps) {
                                var kb = bps / 1024.0
                                var mb = kb / 1024.0
                                if (mb >= 1) return mb.toFixed(1) + " MB/s"
                                if (kb >= 1) return Math.round(kb) + " KB/s"
                                return Math.round(bps) + " B/s"
                            }
                            root.downRate = fmt(dr)
                            root.upRate = fmt(dtb)
                        }
                        root._lastRxBytes = root.rxBytes
                        root._lastTxBytes = root.txBytes
                        root._lastSampleMs = Date.now()
                    }
                }
                if (root.kind !== "disc") {
                    refreshPublicIp()
                } else {
                    root.publicIp = ""
                }
                if (area.containsMouse) {
                    C.Tooltip.show(root, root.buildTooltip())
                }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }

    function refreshPublicIp() {
        if (publicIpProc.running)
            return
        publicIpProc.running = true
    }

    Process {
        id: publicIpProc
        command: ["bash", "-lc", "curl -s --max-time 2 https://ifconfig.me || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = this.text.trim()
                if (value.length && value.indexOf("<") === -1) {
                    root.publicIp = value
                } else {
                    root.publicIp = ""
                }
                if (!area.containsMouse)
                    return
                C.Tooltip.show(root, root.buildTooltip())
            }
        }
        onRunningChanged: {
            if (!running && publicIpRefresh.running && root.kind === "disc")
                publicIpRefresh.stop()
        }
    }

    Timer {
        id: publicIpRefresh
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (root.kind !== "disc") {
                refreshPublicIp()
            } else {
                root.publicIp = ""
            }
        }
    }

    Process { id: run }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: { run.command = ["bash","-lc","networkmanager_dmenu || nm-connection-editor"]; run.running = true }
        onPressed: function(mouse) { if (mouse.button === Qt.RightButton) { run.command = ["bash","-lc","kitty -e nmtui"]; run.running = true } }
        onEntered: {
            C.Tooltip.show(root, root.buildTooltip())
            hoverRefresh.restart()
        }
        onExited: C.Tooltip.hide()
    }

    Timer {
        id: hoverRefresh
        interval: 1000; running: false; repeat: true
        onTriggered: {
            if (area.containsMouse) {
                C.Tooltip.show(root, root.buildTooltip())
            } else {
                hoverRefresh.stop()
            }
        }
    }

    /* Previous implementation showing local IP address
    Text {
        anchors.centerIn: parent
        text: ip && ip.length ? ip : "—"
        color: kind === "disc" ? C.Theme.networkDisconnected : (kind === "wifi" ? C.Theme.networkWifi : C.Theme.networkEthernet)
        font.pixelSize: 12
        enabled: false  // Make text transparent to mouse events
    }
    */

    // Temporary implementation: show only a network icon (WiFi/Ethernet/Disconnected)
    Text {
        id: indicatorText
        anchors.centerIn: parent
        text: root.displayIcon()
        color: kind === "disc" ? C.Theme.networkDisconnected : (kind === "wifi" ? C.Theme.networkWifi : C.Theme.networkEthernet)
        font.pixelSize: C.Theme.fontIcon
        enabled: false  // Make text transparent to mouse events
    }
}
