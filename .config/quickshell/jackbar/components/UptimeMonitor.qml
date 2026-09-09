import Quickshell
import Quickshell.Io
import QtQuick

Item {
    property string uptime: "Unknown"

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim();
                if (text) {
                    uptime = text.replace(/^up\s*/, "");
                } else {
                    // Fallback to /proc/uptime
                    fallbackProc.running = true;
                }
            }
        }
        onExited: {
            if (exitCode !== 0) {
                fallbackProc.running = true;
            }
        }
    }

    Process {
        id: fallbackProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                var seconds = parseInt(this.text.split(" ")[0]);
                var days = Math.floor(seconds / 86400);
                var hours = Math.floor((seconds % 86400) / 3600);
                var mins = Math.floor((seconds % 3600) / 60);
                var parts = [];
                if (days > 0) parts.push(days + " day" + (days > 1 ? "s" : ""));
                if (hours > 0) parts.push(hours + " hour" + (hours > 1 ? "s" : ""));
                if (mins > 0) parts.push(mins + " minute" + (mins > 1 ? "s" : ""));
                uptime = parts.join(", ") || "0 minutes";
            }
        }
    }

    Timer {
        interval: 30000  // Update every 30 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }
}
