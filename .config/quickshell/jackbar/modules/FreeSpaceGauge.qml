import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: C.Theme.panelHeight
    property int freePercent: 0
    property int usedPercent: 0
    property string tip: ""
    property var mounts: []

    property bool _notifiedRootLow: false
    property bool _notifiedHomeLow: false

    readonly property var _LOW_BYTES: 1073741824

    Process { id: diskNotify }

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        color: freePercent < 10 ? C.Theme.freeLow : C.Theme.freeOk
        trackColor: C.Theme.track
        value: usedPercent/100
        label: usedPercent + "%"
    }

    function fmtGB(bytes) {
        if (!bytes || bytes === 0) return "0 GB"
        var gb = bytes / 1024 / 1024 / 1024
        if (gb >= 100) return Math.round(gb) + " GB"
        if (gb >= 10) return gb.toFixed(1) + " GB"
        return gb.toFixed(2) + " GB"
    }

    function fmtPercent(used, total) {
        if (!total || total === 0) return 0
        return Math.round(used * 100 / total)
    }

    function buildProgressBar(percent, width) {
        var filled = Math.floor(width * percent / 100)
        var empty = width - filled
        var bar = ""
        for (var i = 0; i < filled; i++) bar += "█"
        for (var i = 0; i < empty; i++) bar += "░"
        return bar
    }

    function checkDiskSpace() {
        for (var i = 0; i < root.mounts.length; i++) {
            var m = root.mounts[i]
            if (m.mount === "/") {
                if (m.avail < _LOW_BYTES && !_notifiedRootLow) {
                    _notifiedRootLow = true
                    diskNotify.command = ["notify-send", "-u", "critical", "-i", "drive-harddisk", "Disk Space Critical", "Root (/) has only " + fmtGB(m.avail) + " free!"]
                    diskNotify.running = true
                } else if (m.avail >= _LOW_BYTES) {
                    _notifiedRootLow = false
                }
            } else if (m.mount === "/home") {
                if (m.avail < _LOW_BYTES && !_notifiedHomeLow) {
                    _notifiedHomeLow = true
                    diskNotify.command = ["notify-send", "-u", "critical", "-i", "drive-harddisk", "Disk Space Critical", "/home has only " + fmtGB(m.avail) + " free!"]
                    diskNotify.running = true
                } else if (m.avail >= _LOW_BYTES) {
                    _notifiedHomeLow = false
                }
            }
        }
    }

    Process {
        id: proc
        command: ["bash","-lc",
            "df -B1 -x squashfs -x tmpfs -x devtmpfs -x overlay 2>/dev/null | " +
            "awk 'NR>1 && $6 ~ /^\\/$|^\\/home|^\\/run\\/media\\// { " +
            "  gsub(/%/, \"\", $5); " +
            "  print $6\"|\"$2\"|\"$3\"|\"$4\"|\"$5\"|\"$1\"|\"$7 " +
            "}' | sort -t'|' -k1,1"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(function(l) { return l && l.length > 0 })
                root.mounts = []
                var homeInfo = null
                var lowestFree = 100
                var criticalMount = null

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("|")
                    if (parts.length >= 6) {
                        var mount = parts[0]
                        var total = parseFloat(parts[1])
                        var used = parseFloat(parts[2])
                        var avail = parseFloat(parts[3])
                        var usePercent = parseFloat(parts[4])
                        var filesystem = parts[5]
                        var fstype = parts.length >= 7 ? parts[6] : ""

                        var freePercent = total > 0 ? Math.floor(avail * 100 / total) : 0
                        var usedPercent = total > 0 ? Math.floor(used * 100 / total) : 0

                        var mountInfo = {
                            mount: mount,
                            total: total,
                            used: used,
                            avail: avail,
                            usePercent: usePercent,
                            freePercent: freePercent,
                            usedPercent: usedPercent,
                            filesystem: filesystem,
                            fstype: fstype
                        }
                        root.mounts.push(mountInfo)

                        if (mount === "/home") {
                            homeInfo = mountInfo
                        }

                        if (freePercent < lowestFree && mount !== "/") {
                            lowestFree = freePercent
                            criticalMount = mountInfo
                        }
                    }
                }

                var displayInfo = homeInfo || criticalMount
                if (displayInfo) {
                    root.freePercent = displayInfo.freePercent
                    root.usedPercent = displayInfo.usedPercent
                    root.tip = displayInfo.mount + " free: " + fmtGB(displayInfo.avail) + " / " + fmtGB(displayInfo.total)
                }

                checkDiskSpace()
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: proc.running = true }

    Process { id: run }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            run.command = ["bash", "-lc", "kitty --class disk-info -e sh -c 'dysk; read -p \"Press Enter\"'"]
            run.running = true
        }
        onEntered: {
            var tooltipText = buildTooltip()
            C.Tooltip.show(root, tooltipText)
        }
        onExited: C.Tooltip.hide()
    }

    function buildTooltip() {
        if (root.mounts.length === 0) return "Loading..."

        var lines = []
        lines.push("<b>💾 Disk Usage</b>")
        lines.push("")

        for (var i = 0; i < root.mounts.length; i++) {
            var m = root.mounts[i]
            var barWidth = 10
            var bar = buildProgressBar(m.usePercent, barWidth)
            var color = m.freePercent < 10 ? "#ff6b6b" : (m.freePercent < 25 ? "#feca57" : "#48dbfb")

            lines.push("<b>" + m.mount + "</b>  " + fmtGB(m.total))
            lines.push(fmtGB(m.avail) + " free · " + m.freePercent + "%  <font color='" + color + "'>" + bar + "</font>")
            lines.push("<font color='#888888'>" + m.filesystem + (m.fstype ? " (" + m.fstype + ")" : "") + "</font>")
            if (i < root.mounts.length - 1)
                lines.push("")
        }

        return lines.join("<br/>")
    }
}
