import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 40; height: C.Theme.panelHeight
    // Percentage of free space (home)
    property int freePercent: 0
    // Percentage of used/occupied space (for chart display)
    property int usedPercent: 0
    property string tip: ""
    // Store all mount info for tooltip
    property var mounts: []

    C.CircleGauge {
        id: gauge
        anchors.centerIn: parent
        size: 28
        thickness: 4
        // Keep color logic based on free space remaining
        color: freePercent < 10 ? C.Theme.freeLow : C.Theme.freeOk
        trackColor: C.Theme.track
        // Show occupied percentage in the gauge
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

                        // Track home specifically for main gauge
                        if (mount === "/home") {
                            homeInfo = mountInfo
                        }

                        // Track lowest free space for gauge color
                        if (freePercent < lowestFree && mount !== "/") {
                            lowestFree = freePercent
                            criticalMount = mountInfo
                        }
                    }
                }

                // Use home if available, otherwise use most critical mount
                var displayInfo = homeInfo || criticalMount
                if (displayInfo) {
                    root.freePercent = displayInfo.freePercent
                    root.usedPercent = displayInfo.usedPercent
                    root.tip = displayInfo.mount + " free: " + fmtGB(displayInfo.avail) + " / " + fmtGB(displayInfo.total)
                }
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
        var maxMountLen = 10
        var maxFsLen = 8

        // Find max lengths for alignment
        for (var i = 0; i < root.mounts.length; i++) {
            var m = root.mounts[i]
            if (m.mount.length > maxMountLen) maxMountLen = m.mount.length
            if (m.filesystem.length > maxFsLen) maxFsLen = m.filesystem.length
        }

        // Header
        lines.push("<b>💾 Disk Usage</b>")
        lines.push("")

        // Table header
        var header = "<b>Mount Point".padEnd(maxMountLen + 2) +
                     "Size".padStart(10) +
                     "Used".padStart(10) +
                     "Available".padStart(10) +
                     "Use%".padStart(8) +
                     "  Filesystem</b>"
        lines.push(header)
        lines.push("─".repeat(maxMountLen + 50))

        // Rows
        for (var i = 0; i < root.mounts.length; i++) {
            var m = root.mounts[i]
            var barWidth = 10
            var bar = buildProgressBar(m.usePercent, barWidth)
            var color = m.freePercent < 10 ? "#ff6b6b" : (m.freePercent < 25 ? "#feca57" : "#48dbfb")

            var row = m.mount.padEnd(maxMountLen + 2) +
                      fmtGB(m.total).padStart(10) +
                      fmtGB(m.used).padStart(10) +
                      fmtGB(m.avail).padStart(10) +
                      (m.usePercent + "%").padStart(8) +
                      "  <font color='" + color + "'>" + bar + "</font>"
            lines.push(row)

            // Add filesystem on next line for clarity
            var fsLine = "<font color='#888888'>" +
                         " ".repeat(maxMountLen + 2) +
                         m.filesystem +
                         (m.fstype ? " (" + m.fstype + ")" : "") +
                         "</font>"
            lines.push(fsLine)
        }

        return lines.join("<br/>")
    }
}
