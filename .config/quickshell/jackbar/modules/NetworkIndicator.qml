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
    property string ipCountry: ""
    property string ipCountryCode: ""
    property string ipCity: ""
    property string _lastGeoIp: ""
    property string _geoQueryIp: ""
    property double rxBytes: 0
    property double txBytes: 0
    property double _lastRxBytes: 0
    property double _lastTxBytes: 0
    property double _lastSampleMs: 0
    property string downRate: ""
    property string upRate: ""
    property bool vpnActive: false
    property string vpnIface: ""
    property string vpnName: ""
    property string vpnIcon: "󰖂"
    property double vpnRxMb: 0
    property double vpnTxMb: 0
    property bool menuOpen: false
    property double _menuClosedAt: 0

    function icon() {
        if (kind === "wifi") return "󰤨";
        if (kind === "eth") return "󰈀";
        return "󰤭";
    }

    function displayIcon() {
        if (vpnActive)
            return vpnIcon
        return icon()
    }

    function pushPublicIpLines(lines) {
        if (!root.publicIp || !root.publicIp.length)
            return
        lines.push("Public IP: " + root.publicIp)
        var loc = ""
        if (root.ipCity && root.ipCity.length)
            loc += root.ipCity + ", "
        if (root.ipCountry && root.ipCountry.length)
            loc += root.ipCountry
        if (root.ipCountryCode && root.ipCountryCode.length)
            loc += " (" + root.ipCountryCode + ")"
        if (loc.length)
            lines.push("Location: " + loc)
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
            pushPublicIpLines(lines)
            lines.push("󰇚 " + down + " | 󰕒 " + up)
        } else if (root.kind === "eth") {
            if (root.iface && root.iface.length) lines.push("Interface: " + root.iface)
            if (root.ip && root.ip.length) lines.push("Local IP: " + root.ip)
            if (root.gateway && root.gateway.length) lines.push("Gateway: " + root.gateway)
            pushPublicIpLines(lines)
            lines.push("󰇚 " + down + " | 󰕒 " + up)
        } else {
            lines.push("Disconnected")
        }
        if (vpnActive) {
            var label = root.vpnName && root.vpnName.length ? root.vpnName : (root.vpnIface && root.vpnIface.length ? root.vpnIface : "VPN")
            var suffix = (root.ipCountryCode && root.ipCountryCode.length) ? " [" + root.ipCountryCode + "]" : ""
            lines.push("VPN: Active (" + label + ")" + suffix)
            lines.push("󰇚 " + root.vpnRxMb.toFixed(1) + " MB | 󰕒 " + root.vpnTxMb.toFixed(1) + " MB")
        } else {
            lines.push("VPN: Off")
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
                        root.rxBytes = parseFloat(rt[0]) || 0
                        root.txBytes = parseFloat(rt[1]) || 0
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
                    clearGeo()
                }
                if (area.containsMouse && !root.menuOpen) {
                    C.Tooltip.show(root, root.buildTooltip())
                }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: { proc.running = true; vpnProc.running = true } }

    function refreshPublicIp() {
        if (publicIpProc.running)
            return
        publicIpProc.running = true
    }

    function clearGeo() {
        root.ipCountry = ""
        root.ipCountryCode = ""
        root.ipCity = ""
        root._lastGeoIp = ""
    }

    function refreshGeo(ipAddr) {
        if (!ipAddr || !ipAddr.length || geoProc.running)
            return
        root._geoQueryIp = ipAddr
        geoProc.command = ["/home/jacky/dotfiles/.config/quickshell/jackbar/modules/geo-lookup.sh", ipAddr]
        geoProc.running = true
    }

    Process {
        id: publicIpProc
        command: ["bash", "-lc", "curl -s --max-time 2 https://ifconfig.me || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = this.text.trim()
                if (value.length && value.indexOf("<") === -1) {
                    root.publicIp = value
                    // Only resolve the country when the exit IP changed —
                    // repeated polls for the same IP reuse the cached values.
                    if (value !== root._lastGeoIp)
                        refreshGeo(value)
                } else {
                    root.publicIp = ""
                    clearGeo()
                }
                if (!area.containsMouse || root.menuOpen)
                    return
                C.Tooltip.show(root, root.buildTooltip())
            }
        }
        onRunningChanged: {
            if (!running && publicIpRefresh.running && root.kind === "disc")
                publicIpRefresh.stop()
        }
    }

    Process {
        id: geoProc
        stdout: StdioCollector {
            onStreamFinished: {
                var gparts = this.text.trim().split("|")
                if (gparts.length >= 2 && (gparts[0].length || gparts[1].length)) {
                    root.ipCountry = gparts[0]
                    root.ipCountryCode = gparts[1]
                    // Belt-and-braces: drop "City of " prefix even if a stale
                    // value slipped through (script normalizes at source too).
                    var city = gparts.length >= 3 ? gparts[2] : ""
                    root.ipCity = city.replace(/^City of /, "")
                    // Mark this IP as resolved so we skip lookups until it changes.
                    // On failure _lastGeoIp stays unset, so the next cycle retries.
                    root._lastGeoIp = root._geoQueryIp
                }
                if (!area.containsMouse || root.menuOpen)
                    return
                C.Tooltip.show(root, root.buildTooltip())
            }
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
                clearGeo()
            }
        }
    }

    Process { id: run }

    function toggleMenu() {
        if (Date.now() - root._menuClosedAt < 250)
            return
        root.menuOpen = !root.menuOpen
        if (root.menuOpen)
            C.Tooltip.hide()
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                run.command = ["bash", "-lc", "kitty -e nmtui"]
                run.running = true
                return
            }
            toggleMenu()
        }
        onEntered: {
            if (root.menuOpen)
                return
            C.Tooltip.show(root, root.buildTooltip())
            hoverRefresh.restart()
        }
        onExited: {
            if (!root.menuOpen)
                C.Tooltip.hide()
        }
    }

    Timer {
        id: hoverRefresh
        interval: 1000; running: false; repeat: true
        onTriggered: {
            if (area.containsMouse && !root.menuOpen) {
                C.Tooltip.show(root, root.buildTooltip())
            } else {
                hoverRefresh.stop()
            }
        }
    }

    Timer {
        id: panelRefresh
        interval: 1000
        running: root.menuOpen
        repeat: true
        onTriggered: {
            proc.running = true
            vpnProc.running = true
        }
    }

    NetworkPanel {
        anchorItem: root
        menuOpen: root.menuOpen
        kind: root.kind
        ssid: root.ssid
        iface: root.iface
        ip: root.ip
        gateway: root.gateway
        downRate: root.downRate
        upRate: root.upRate
        rxBytes: root.rxBytes
        txBytes: root.txBytes
        maxHeight: {
            var win = QsWindow.window
            if (win && win.screen)
                return Math.max(360, win.screen.height - C.Theme.panelHeight - 12)
            return 700
        }
        vpnActive: root.vpnActive
        vpnName: root.vpnName
        vpnIface: root.vpnIface
        onDismissed: {
            root.menuOpen = false
            root._menuClosedAt = Date.now()
        }
    }

    Process {
        id: vpnProc
        command: ["/home/jacky/dotfiles/.config/quickshell/jackbar/modules/vpn-detect.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var vparts = this.text.trim().split("|")
                root.vpnActive = (vparts[0] === "active")
                if (root.vpnActive) {
                    if (vparts.length >= 5) {
                        // New format: active|iface|conn|rx|tx
                        root.vpnIface = vparts[1]
                        root.vpnName = vparts[2]
                        root.vpnRxMb = parseInt(vparts[3]) / (1024.0 * 1024.0)
                        root.vpnTxMb = parseInt(vparts[4]) / (1024.0 * 1024.0)
                    } else if (vparts.length >= 3) {
                        // Legacy format: active|rx|tx
                        root.vpnIface = ""
                        root.vpnName = ""
                        root.vpnRxMb = parseInt(vparts[1]) / (1024.0 * 1024.0)
                        root.vpnTxMb = parseInt(vparts[2]) / (1024.0 * 1024.0)
                    } else {
                        root.vpnIface = ""
                        root.vpnName = ""
                        root.vpnRxMb = 0
                        root.vpnTxMb = 0
                    }
                } else {
                    root.vpnIface = ""
                    root.vpnName = ""
                    root.vpnRxMb = 0
                    root.vpnTxMb = 0
                }
                if (area.containsMouse && !root.menuOpen)
                    C.Tooltip.show(root, root.buildTooltip())
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
