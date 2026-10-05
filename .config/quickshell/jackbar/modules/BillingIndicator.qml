import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: Math.max(indicatorText.implicitWidth + 8, 40)
    height: C.Theme.panelHeight

    property bool loading: true
    property var providers: []
    property int warnPercent: 70
    property int criticalPercent: 90
    property int pollMs: 300000
    property string status: "loading" // loading | ok | warn | crit | error
    property string firstDashboard: ""

    readonly property color iconColor: {
        if (status === "crit")
            return C.Theme.billingCrit
        if (status === "warn")
            return C.Theme.billingWarn
        if (status === "loading" || status === "error")
            return C.Theme.grayMuted
        return C.Theme.billingOk
    }

    function isNum(v) {
        return v !== null && v !== undefined && v !== "" && isFinite(Number(v))
    }

    function fmtUsd(v) {
        if (!isNum(v))
            return "-"
        return "$" + Number(v).toFixed(2)
    }

    function fmtTokens(v) {
        if (!isNum(v) || Number(v) <= 0)
            return ""
        var n = Number(v)
        if (n >= 1000000)
            return (n / 1000000).toFixed(2) + "M tok"
        if (n >= 1000)
            return (n / 1000).toFixed(1) + "k tok"
        return Math.round(n) + " tok"
    }

    function fmtBytes(v) {
        if (!isNum(v) || Number(v) <= 0)
            return ""
        var n = Number(v)
        if (n >= 1048576)
            return (n / 1048576).toFixed(1) + " MB"
        if (n >= 1024)
            return (n / 1024).toFixed(1) + " KB"
        return Math.round(n) + " B"
    }

    function periodLabel(p) {
        if (p === "daily")
            return "Daily"
        if (p === "weekly")
            return "Weekly"
        if (p === "monthly")
            return "Monthly"
        if (p === "rolling" || p === "key")
            return p === "key" ? "Key" : "Rolling"
        if (p === "go-rolling")
            return "Go rolling"
        if (p === "go-weekly")
            return "Go weekly"
        if (p === "go-monthly")
            return "Go monthly"
        if (p === "cycle")
            return "Cycle"
        if (p === "included")
            return "Included"
        if (p === "on-demand")
            return "On-demand"
        return p || "Limit"
    }

    function buildProgressBar(percent, width) {
        var p = Math.max(0, Math.min(100, percent || 0))
        var filled = Math.floor(width * p / 100)
        var empty = width - filled
        var bar = ""
        var i
        for (i = 0; i < filled; i++)
            bar += "█"
        for (i = 0; i < empty; i++)
            bar += "░"
        return bar
    }

    function barColor(percent) {
        if (!isNum(percent))
            return "#48dbfb"
        var p = Number(percent)
        if (p >= root.criticalPercent)
            return "#ff6b6b"
        if (p >= root.warnPercent)
            return "#feca57"
        return "#48dbfb"
    }

    function computeStatus(list) {
        var worst = "ok"
        var hasOk = false
        var i, j, p, lim, pct, rem
        if (!list || list.length === 0)
            return "error"
        for (i = 0; i < list.length; i++) {
            p = list[i]
            if (!p.ok)
                continue
            hasOk = true
            rem = p.remaining_usd
            if (isNum(rem) && Number(rem) <= 1)
                return "crit"
            if (!p.limits)
                continue
            for (j = 0; j < p.limits.length; j++) {
                lim = p.limits[j]
                pct = lim && lim.percent
                if (!isNum(pct))
                    continue
                if (Number(pct) >= root.criticalPercent)
                    return "crit"
                if (Number(pct) >= root.warnPercent)
                    worst = "warn"
            }
        }
        return hasOk ? worst : "error"
    }

    function todaySpentLine(p) {
        var tok = fmtTokens(p.tokens_today)
        var size = fmtBytes(p.bytes_est)
        var usd = fmtUsd(p.spent_today_usd)
        var left = ""
        if (tok) {
            left = tok
            if (size)
                left += " (~" + size + ")"
        } else if (size) {
            left = size
        }
        if (left && usd !== "-")
            return left + ", " + usd
        if (left)
            return left
        return usd
    }

    function limitOrder(period) {
        var p = String(period || "")
        if (p === "daily")
            return 0
        if (p === "weekly")
            return 1
        if (p === "monthly")
            return 2
        if (p === "included")
            return 3
        if (p === "on-demand")
            return 4
        if (p === "cycle")
            return 5
        if (p === "key")
            return 6
        if (p.indexOf("go-") === 0)
            return 10
        return 20
    }

    function sortedLimits(list) {
        if (!list || !list.length)
            return []
        var copy = []
        var i
        for (i = 0; i < list.length; i++)
            copy.push(list[i])
        copy.sort(function(a, b) {
            return limitOrder(a && a.period) - limitOrder(b && b.period)
        })
        return copy
    }

    function buildTooltip() {
        if (root.loading && root.providers.length === 0)
            return ""
        if (!root.providers || root.providers.length === 0)
            return "No billing providers enabled"

        var lines = []
        var i, j, p, lim, pct, color, bar, used, cap
        for (i = 0; i < root.providers.length; i++) {
            p = root.providers[i]
            if (i > 0)
                lines.push("")
            if (p.ok === false && p.error)
                lines.push("<b>" + (i + 1) + ". " + (p.name || p.id) + "</b> — " + p.error)
            else {
                var suffix = " left"
                var unlimited = false
                if (p.limits) {
                    for (j = 0; j < p.limits.length; j++) {
                        if (p.limits[j] && p.limits[j].period === "included") {
                            suffix = " included left"
                            break
                        }
                    }
                    for (j = 0; j < p.limits.length; j++) {
                        if (p.limits[j] && p.limits[j].period === "monthly" && !isNum(p.limits[j].limit) && !p.limits[j].spent)
                            unlimited = true
                    }
                }
                var rem = unlimited && !isNum(p.remaining_usd)
                    ? "unlimited"
                    : fmtUsd(p.remaining_usd) + suffix
                lines.push("<b>" + (i + 1) + ". " + (p.name || p.id) + "</b> — " + rem)
                if (p.ok !== false && p.error)
                    lines.push("<font color='#888888'>" + p.error + "</font>")
            }
            lines.push("Daily  " + todaySpentLine(p))
            if (p.limits && p.limits.length) {
                var lims = sortedLimits(p.limits)
                for (j = 0; j < lims.length; j++) {
                    lim = lims[j]
                    // Daily spent is already the "Daily  …" line above.
                    if (lim.period === "daily" && !isNum(lim.limit))
                        continue
                    // Included 100% duplicates the header ("$0.00 included left").
                    // Keep the bar only while some included budget remains.
                    if (lim.period === "included") {
                        var inclExhausted = (isNum(lim.percent) && Number(lim.percent) >= 99.5)
                            || (isNum(lim.used) && isNum(lim.limit) && Number(lim.limit) > 0
                                && Number(lim.used) >= Number(lim.limit) - 0.005)
                        if (inclExhausted)
                            continue
                    }
                    pct = isNum(lim.percent) ? Number(lim.percent) : 0
                    color = barColor(lim.percent)
                    bar = buildProgressBar(pct, 10)
                    used = fmtUsd(lim.used)
                    cap = fmtUsd(lim.limit)
                    if (String(lim.period).indexOf("go-") === 0)
                        lines.push(periodLabel(lim.period) + "  <font color='" + color + "'>" + bar + "</font>  " + Math.round(pct) + "%")
                    else if (!isNum(lim.limit)) {
                        var tok = fmtTokens(lim.tokens)
                        lines.push(periodLabel(lim.period) + "  " + (tok ? tok + ", " : "") + used)
                    }
                    else
                        lines.push(periodLabel(lim.period) + "  <font color='" + color + "'>" + bar + "</font>  " + Math.round(pct) + "%  " + used + " / " + cap)
                }
            }
            if (p.renew_line)
                lines.push(p.renew_line)
        }
        lines.push("_________")
        lines.push("<span style='font-size:15px;color:#888888;white-space:nowrap'>Left click: copy tooltip</span>")
        lines.push("<span style='font-size:15px;color:#888888;white-space:nowrap'>Right click: refresh</span>")
        return lines.join("<br/>")
    }

    function htmlToPlain(html) {
        var t = String(html || "")
        t = t.replace(/<br\s*\/?>/gi, "\n")
        t = t.replace(/<[^>]+>/g, "")
        t = t.replace(/&amp;/g, "&")
        t = t.replace(/&lt;/g, "<")
        t = t.replace(/&gt;/g, ">")
        t = t.replace(/&nbsp;/g, " ")
        t = t.replace(/\n{3,}/g, "\n\n")
        return t.trim()
    }

    function copyTooltip() {
        if (root.loading && root.providers.length === 0)
            return
        var text = htmlToPlain(buildTooltip())
        if (!text.length)
            return
        run.command = ["wl-copy", "--", text]
        run.running = true
        notify.command = ["notify-send", "-t", "1500", "-a", "jackbar", "Billing", "Copied to clipboard"]
        notify.running = true
    }

    function applyResult(obj) {
        if (!obj)
            return
        if (obj.warn_percent != null)
            root.warnPercent = obj.warn_percent
        if (obj.critical_percent != null)
            root.criticalPercent = obj.critical_percent
        if (obj.poll_seconds && obj.poll_seconds > 0)
            root.pollMs = obj.poll_seconds * 1000
        root.providers = obj.providers || []
        root.firstDashboard = ""
        for (var i = 0; i < root.providers.length; i++) {
            if (root.providers[i].dashboard_url) {
                root.firstDashboard = root.providers[i].dashboard_url
                break
            }
        }
        root.status = computeStatus(root.providers)
        root.loading = false
        if (area.containsMouse)
            C.Tooltip.show(root, root.buildTooltip(), false, { maxWidth: 420 })
    }

    function refresh() {
        root.loading = true
        proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-lc", "$HOME/dotfiles/.config/quickshell/jackbar/modules/billing/billing-status.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    root.applyResult(obj)
                } catch (e) {
                    root.loading = false
                    root.status = "error"
                    root.providers = [{
                        id: "error",
                        name: "Billing",
                        ok: false,
                        error: "parse error",
                        remaining_usd: null,
                        spent_today_usd: null,
                        tokens_today: null,
                        bytes_est: null,
                        limits: []
                    }]
                }
            }
        }
    }

    Timer {
        interval: root.pollMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Process { id: run }
    Process { id: notify }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                C.Tooltip.hide()
                root.refresh()
                return
            }
            root.copyTooltip()
        }
        onEntered: {
            var html = root.buildTooltip()
            if (!html.length)
                return
            C.Tooltip.show(root, html, false, { maxWidth: 420 })
        }
        onExited: C.Tooltip.hide()
    }

    Item {
        id: billingSpinner
        anchors.centerIn: parent
        width: 16
        height: 16
        visible: root.loading
        property color strokeColor: C.Theme.billingOk

        Canvas {
            id: billingSpinnerCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.strokeStyle = billingSpinner.strokeColor
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, (width - 4) / 2, Math.PI * 0.2, Math.PI * 1.7)
                ctx.stroke()
            }
        }

        NumberAnimation on rotation {
            running: root.loading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
            easing.type: Easing.Linear
        }

        onStrokeColorChanged: billingSpinnerCanvas.requestPaint()
        Component.onCompleted: billingSpinnerCanvas.requestPaint()
    }

    Text {
        id: indicatorText
        anchors.centerIn: parent
        text: "󰚩"
        color: root.iconColor
        font.pixelSize: C.Theme.fontIcon
        enabled: false
        visible: !root.loading
    }
}
