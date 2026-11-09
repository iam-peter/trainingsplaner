import QtQuick
import QtTest
import Trainingsplaner

// A week typed as WW/JJJJ or picked from the field's calendar, like a date
Item {
    width: 800
    height: 600

    WeekField {
        id: field
        x: 20
        y: 20
    }

    SignalSpy { id: edits; target: field; signalName: "textEdited" }
    SignalSpy { id: picks; target: field; signalName: "weekPicked" }

    TestCase {
        name: "WeekField"
        when: windowShown

        function test_typedAndPicked() {
            field.text = "47/2026"
            compare(field.monday, "2026-11-16")
            const calendar = findChild(field, "weekCalendar")
            mouseClick(findChild(field, "calendarButton"))
            tryCompare(calendar, "opened", true)
            compare(calendar.monday, "2026-11-16")      // opens at the typed week
            compare(calendar.month, 10)
            calendar.pick("2026-11-30")                 // as a click on week 49
            compare(field.text, "49/2026")
            compare(edits.count, 1)
            compare(picks.count, 1)
            compare(picks.signalArguments[0][0], "2026-11-30")
            tryCompare(calendar, "visible", false)
        }

        function test_emptyOpensAtThisWeek() {
            field.text = ""
            compare(field.monday, "")
            const calendar = findChild(field, "weekCalendar")
            compare(calendar.monday, Store.mondayOf(Store.today()))
        }
    }
}
