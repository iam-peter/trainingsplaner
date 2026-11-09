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
            // The grid starts with the week of the 1st (November 2026
            // begins on a Sunday), numbered by ISO weeks, also across the
            // year's end
            compare(calendar.firstMonday, "2026-10-26")
            compare(calendar.weekNumber("2026-10-26"), 44)
            compare(calendar.weekNumber("2026-11-23"), 48)
            compare(calendar.weekNumber("2026-12-28"), 53)   // 2026 has 53 weeks
            compare(calendar.weekNumber("2027-01-04"), 1)
            compare(calendar.weekNumber("2027-12-27"), 52)
            compare(calendar.weekNumber("2025-12-29"), 1)    // week 1 of 2026

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
