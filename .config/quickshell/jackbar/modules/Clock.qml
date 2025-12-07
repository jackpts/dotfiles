import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components" as C

Item {
    id: root
    width: 110
    height: 50

    property int calendarOffset: 0

    function getCalendarMonth() {
        let now = new Date()
        let targetDate = new Date(now.getFullYear(), now.getMonth() + calendarOffset, 1)
        return targetDate
    }

    function generateCalendar() {
        let targetDate = getCalendarMonth()
        let year = targetDate.getFullYear()
        let month = targetDate.getMonth()
        
        let monthNames = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
        
        // Shift to Monday-first: JS getDay() -> 0=Sun..6=Sat; convert to 0=Mon..6=Sun
        let firstDay = (new Date(year, month, 1).getDay() + 6) % 7
        let daysInMonth = new Date(year, month + 1, 0).getDate()
        
        let today = new Date()
        let isCurrentMonth = (today.getFullYear() === year && today.getMonth() === month)
        let todayDate = today.getDate()
        
        let calendar = `<pre>`
        calendar += `<span style="color: ${C.Theme.calendarHeader}; font-weight: bold; font-size: 16px;">${monthNames[month]} ${year}</span>\n\n`
        calendar += `<span style=\"color: ${C.Theme.calendarDow}; font-weight: bold;\">Mo Tu We Th Fr Sa Su</span>\n`
        
        let dayStr = ""
        for (let i = 0; i < firstDay; i++) {
            dayStr += "   "
        }
        
        for (let day = 1; day <= daysInMonth; day++) {
            let isToday = (isCurrentMonth && day === todayDate)
            let color = isToday ? C.Theme.calendarToday : C.Theme.text
            let weight = isToday ? "bold" : "normal"
            
            dayStr += `<span style="color: ${color}; font-weight: ${weight};">${day.toString().padStart(2, ' ')}</span> `
            
            if ((firstDay + day) % 7 === 0) {
                calendar += dayStr + "\n"
                dayStr = ""
            }
        }
        
        if (dayStr.length > 0) {
            calendar += dayStr + "\n"
        }
        
        calendar += `</pre>`
        return calendar
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm, dd MMM")
        color: C.Theme.clock
        font.pixelSize: 18
    }

    Process { id: run }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            C.Tooltip.show(clockText, root.generateCalendar(), true)
        }
        
        onExited: {
            C.Tooltip.hide()
        }
        
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                // Scroll up - previous month
                root.calendarOffset--
            } else {
                // Scroll down - next month
                root.calendarOffset++
            }
            // Update tooltip with new month
            C.Tooltip.show(clockText, root.generateCalendar(), true)
        }
        
        onClicked: {
            run.command = ["bash", "-c", "gnome-calendar"]
            run.running = true
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
