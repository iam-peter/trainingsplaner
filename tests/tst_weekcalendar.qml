import QtQuick
import QtTest
import Trainingsplaner

// The week calendar: the week under the pointer is marked, and a week
// number picks its week like a day does
Item {
    width: 600
    height: 500

    WeekCalendar {
        id: calendar
        x: 20
        y: 20
        monday: "2026-11-09"
    }

    SignalSpy {
        id: picks
        target: calendar
        signalName: "picked"
    }

    TestCase {
        name: "WeekCalendar"
        when: windowShown

        function test_hoverAndWeekNumber() {
            calendar.open()
            tryCompare(calendar, "opened", true)
            // November 2026 starts on a Sunday: the grid's first row is the
            // week of Monday, 26 October
            compare(calendar.rowMonday(0), "2026-10-26")
            compare(calendar.rowMonday(4), "2026-11-23")

            const week48 = findChild(calendar.contentItem, "week48")
            verify(week48)
            mouseMove(week48, week48.width / 2, week48.height / 2)
            tryCompare(calendar, "hovered", "2026-11-23")
            mouseClick(week48)
            compare(picks.count, 1)
            compare(picks.signalArguments[0][0], "2026-11-23")
            tryCompare(calendar, "visible", false)
            compare(calendar.hovered, "")
        }
    }
}
