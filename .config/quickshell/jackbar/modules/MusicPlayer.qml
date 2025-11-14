import Quickshell
import Quickshell.Io
import QtQuick
import "../components" as C

Item {
    id: root
    width: textWidth + 40
    height: 40
    
    property string artist: ""
    property string title: ""
    property string status: "Stopped"
    property string playerName: ""
    property int textWidth: 150
    property int maxTextLength: 25
    
    property bool useNerdFont: true  // Set to false if icons don't show
    
    function icon() {
        if (useNerdFont) {
            if (status === "Playing") return "󰐊"
            if (status === "Paused") return "󰏤"
            return "󰝚"
        } else {
            // ASCII fallback
            if (status === "Playing") return "▶"
            if (status === "Paused") return "⏸"
            return "◼"
        }
    }
    
    function truncateText(text, maxLen) {
        if (!text || text.length === 0) return ""
        if (text.length <= maxLen) return text
        return text.substring(0, maxLen - 3) + "..."
    }
    
    function getDisplayText() {
        if (!artist && !title) return "No media"
        
        var fullText = ""
        if (artist) fullText += artist
        if (artist && title) fullText += " - "
        if (title) fullText += title
        
        return truncateText(fullText, maxTextLength)
    }
    
    function getTooltipText() {
        if (!artist && !title) return "No media playing"
        
        var tooltip = ""
        if (playerName) tooltip += "Player: " + playerName + "<br>"
        if (title) tooltip += "Title: " + title + "<br>"
        if (artist) tooltip += "Artist: " + artist + "<br>"
        tooltip += "Status: " + status + "<br><br>"
        tooltip += "Left Click: Play/Pause<br>"
        tooltip += "Right Click: Stop<br>"
        tooltip += "Scroll: Next/Previous"
        
        return tooltip
    }
    
    Process { 
        id: metadataProc
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim()
                var lines = output.split('\n')
                
                // We expect exactly 5 lines (with blanks): title, blank, artist, blank, status
                // Or if artist is empty: title, blank, blank, blank, status
                if (lines.length >= 5) {
                    root.title = lines[0].trim()
                    root.artist = lines[2].trim()  // Artist is on line 3 (index 2)
                    root.status = lines[4].trim()  // Status is on line 5 (index 4)
                } else if (lines.length >= 3) {
                    // Fallback: might have fewer lines
                    root.title = lines[0].trim()
                    root.artist = lines[1].trim()
                    root.status = lines[2].trim()
                } else {
                    // Minimal fallback
                    root.title = lines[0] ? lines[0].trim() : ""
                    root.artist = ""
                    root.status = "Stopped"
                }
            }
        }
    }
    
    Process {
        id: playerProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.playerName = this.text.trim()
            }
        }
    }
    
    // Process to select the best player
    property string selectedPlayer: ""
    property int updateCycle: 0
    Process {
        id: selectPlayerProc
        stdout: StdioCollector {
            onStreamFinished: {
                var player = this.text.trim()
                root.selectedPlayer = player
                
                // Now fetch metadata for the selected player
                if (player) {
                    // Use printf to properly handle newlines
                    var metaCmd = "playerctl -p " + player + " metadata --format '{{title}}' 2>/dev/null; " +
                                  "printf '\\n'; " +
                                  "playerctl -p " + player + " metadata --format '{{artist}}' 2>/dev/null; " +
                                  "printf '\\n'; " +
                                  "playerctl -p " + player + " status 2>/dev/null || echo 'Stopped'"
                    metadataProc.command = ["bash", "-c", metaCmd]
                    metadataProc.running = true
                    
                    playerProc.command = ["bash", "-c", "playerctl -p " + player + " metadata --format '{{playerName}}' 2>/dev/null || echo ''"]
                    playerProc.running = true
                } else {
                    root.title = ""
                    root.artist = ""
                    root.status = "Stopped"
                    root.playerName = ""
                }
            }
        }
    }
    
    Timer {
        interval: 1000  // Update every second for faster track change detection
        running: true
        repeat: true
        onTriggered: {
            // If we already have a selected player, just update its metadata directly
            if (root.selectedPlayer) {
                var metaCmd = "playerctl -p " + root.selectedPlayer + " metadata --format '{{title}}' 2>/dev/null; " +
                              "printf '\\n'; " +
                              "playerctl -p " + root.selectedPlayer + " metadata --format '{{artist}}' 2>/dev/null; " +
                              "printf '\\n'; " +
                              "playerctl -p " + root.selectedPlayer + " status 2>/dev/null || echo 'Stopped'"
                metadataProc.command = ["bash", "-c", metaCmd]
                metadataProc.running = true
            }
            
            // Every few cycles, re-check for player changes
            if (root.updateCycle % 5 === 0) {
                // Smart player selection script:
                // 1. Get all players with their status
                // 2. Prefer Playing over Paused
                // 3. Prefer dedicated players (kew, spotify, etc.) over browsers
                var cmd = `
                    # Get best player based on priority
                    players=$(playerctl -l 2>/dev/null)
                    [ -z "$players" ] && echo "" && exit 0
                    
                    # Priority list: prefer dedicated music players over browsers
                    priority="kew spotify vlc mpv rhythmbox"
                    
                    # First, try to find any Playing player, prioritized
                    for p in $priority; do
                        echo "$players" | grep -q "^$p" && 
                        [ "$(playerctl -p $p status 2>/dev/null)" = "Playing" ] && 
                        echo "$p" && exit 0
                    done
                    
                    # Then try any Playing player (including browsers)
                    for player in $players; do
                        [ "$(playerctl -p $player status 2>/dev/null)" = "Playing" ] && 
                        echo "$player" && exit 0
                    done
                    
                    # Fall back to prioritized player even if paused
                    for p in $priority; do
                        echo "$players" | grep -q "^$p" && echo "$p" && exit 0
                    done
                    
                    # Finally, use first available player
                    echo "$players" | head -n1
                `
                
                selectPlayerProc.command = ["bash", "-c", cmd]
                selectPlayerProc.running = true
            }
            
            root.updateCycle++
        }
    }
    
    Component.onCompleted: {
        // Trigger initial player selection
        var cmd = `
            # Get best player based on priority
            players=$(playerctl -l 2>/dev/null)
            [ -z "$players" ] && echo "" && exit 0
            
            # Priority list: prefer dedicated music players over browsers
            priority="kew spotify vlc mpv rhythmbox"
            
            # First, try to find any Playing player, prioritized
            for p in $priority; do
                echo "$players" | grep -q "^$p" && 
                [ "$(playerctl -p $p status 2>/dev/null)" = "Playing" ] && 
                echo "$p" && exit 0
            done
            
            # Then try any Playing player (including browsers)
            for player in $players; do
                [ "$(playerctl -p $player status 2>/dev/null)" = "Playing" ] && 
                echo "$player" && exit 0
            done
            
            # Fall back to prioritized player even if paused
            for p in $priority; do
                echo "$players" | grep -q "^$p" && echo "$p" && exit 0
            done
            
            # Finally, use first available player
            echo "$players" | head -n1
        `
        
        selectPlayerProc.command = ["bash", "-c", cmd]
        selectPlayerProc.running = true
    }
    
    Process { id: controlProc }
    
    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: {
            // Re-select player after user interaction
            var cmd = `
                # Get best player based on priority
                players=$(playerctl -l 2>/dev/null)
                [ -z "$players" ] && echo "" && exit 0
                
                # Priority list: prefer dedicated music players over browsers
                priority="kew spotify vlc mpv rhythmbox"
                
                # First, try to find any Playing player, prioritized
                for p in $priority; do
                    echo "$players" | grep -q "^$p" && 
                    [ "$(playerctl -p $p status 2>/dev/null)" = "Playing" ] && 
                    echo "$p" && exit 0
                done
                
                # Then try any Playing player (including browsers)
                for player in $players; do
                    [ "$(playerctl -p $player status 2>/dev/null)" = "Playing" ] && 
                    echo "$player" && exit 0
                done
                
                # Fall back to prioritized player even if paused
                for p in $priority; do
                    echo "$players" | grep -q "^$p" && echo "$p" && exit 0
                done
                
                # Finally, use first available player
                echo "$players" | head -n1
            `
            
            selectPlayerProc.command = ["bash", "-c", cmd]
            selectPlayerProc.running = true
        }
    }
    
    Row {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon()
            color: {
                if (status === "Playing") return C.Theme.green
                if (status === "Paused") return C.Theme.yellow
                return C.Theme.grayMuted
            }
            font.pixelSize: 18
            font.family: "monospace"  // Ensure font supports icons
            visible: status !== "Stopped" || title || artist
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.getDisplayText()
            color: status === "Playing" ? C.Theme.text : C.Theme.textMuted
            font.pixelSize: 12
            width: root.textWidth
            elide: Text.ElideRight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                var player = root.selectedPlayer ? "-p " + root.selectedPlayer : ""
                controlProc.command = ["bash", "-c", "playerctl " + player + " play-pause"]
                controlProc.running = true
            } else if (mouse.button === Qt.RightButton) {
                var player = root.selectedPlayer ? "-p " + root.selectedPlayer : ""
                controlProc.command = ["bash", "-c", "playerctl " + player + " stop"]
                controlProc.running = true
            }
            updateTimer.restart()
        }
        
        onWheel: function(wheel) {
            var player = root.selectedPlayer ? "-p " + root.selectedPlayer : ""
            if (wheel.angleDelta.y > 0) {
                controlProc.command = ["bash", "-c", "playerctl " + player + " previous"]
            } else {
                controlProc.command = ["bash", "-c", "playerctl " + player + " next"]
            }
            controlProc.running = true
            updateTimer.restart()
        }
        
        onEntered: {
            C.Tooltip.show(root, root.getTooltipText())
        }
        
        onExited: {
            C.Tooltip.hide()
        }
    }
}
