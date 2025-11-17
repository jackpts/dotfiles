/*------------------------------------
--- Shazam.qml - widgets by andrel ---
------------------------------------*/

import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: 32
    height: 40
    
    // True while we are recording + recognizing
    property bool searching: false
    // In-memory history of last recognized songs (most recent first)
    property var history: []
    property int maxHistory: 30
    
    function icon() {
        return "󰓃"  // music note icon
    }
    
    function addToHistory(entry) {
        if (!entry || entry === "No match")
            return
        // Avoid duplicate consecutive entries
        if (history.length > 0 && history[0] === entry)
            return
        history.unshift(entry)
        if (history.length > maxHistory)
            history.splice(maxHistory, history.length - maxHistory)
    }
    
    function historyTooltip() {
        if (searching)
            return "Listening..."
        if (!history || history.length === 0)
            return "Music Recognition<br><br>Click to identify current song."
        var text = "Music Recognition<br><br>Last recognized songs:<br>"
        for (var i = 0; i < history.length; ++i) {
            text += (i + 1) + ". " + history[i] + "<br>"
        }
        return text
    }
    
    // Process for desktop notifications (notify-send)
    Process { id: notifyProc }
    
    function notify(summary) {
        if (!summary)
            return
        var label = "Music recognition"
        var body = summary.replace(/"/g, '\\"')
        var cmd = "notify-send \"" + label + "\" \"" + body + "\""
        notifyProc.command = ["bash", "-lc", cmd]
        notifyProc.running = true
    }
    
    // Process running the helper script that records + calls songrec
    Process {
        id: shazamProc
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                var summary
                if (!output) {
                    summary = "No match"
                } else {
                    // Show the first line as tooltip; helper already formats it
                    var firstLine = output.split('\n')[0]
                    summary = firstLine || "No match"
                }
                root.addToHistory(summary)
                C.Tooltip.show(root, summary)
                root.notify(summary)
                root.searching = false
            }
        }
        onExited: {
            // Ensure we reset state even if the process fails
            if (root.searching) {
                root.searching = false
                // Keep last tooltip; user can hover again to see it
            }
        }
    }
    
    function toggleShazam() {
        if (searching) {
            // Best-effort cancel: stop the process
            shazamProc.running = false
            searching = false
            C.Tooltip.show(root, historyTooltip())
            return
        }
        
        // Start a new recognition
        searching = true
        C.Tooltip.show(root, "Listening...")
        
        // Use helper script that records a short sample then calls songrec
        // See: $HOME/dotfiles/scripts/quickshell_shazam.sh
        shazamProc.command = [
            "bash", "-lc",
            "\"$HOME/dotfiles/scripts/quickshell_shazam.sh\" || echo 'No match'"
        ]
        shazamProc.running = true
    }
    
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.toggleShazam()
        onEntered: C.Tooltip.show(root, historyTooltip())
        onExited: C.Tooltip.hide()
    }
    
    Text {
        anchors.centerIn: parent
        text: root.icon()
        color: searching ? "#89b4fa" : "#6c7086"  // blue when active, gray when inactive
        font.pixelSize: 18
        enabled: false
    }
}
