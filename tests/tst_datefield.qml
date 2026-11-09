import QtQuick
import QtTest
import Trainingsplaner

// A date picked in the calendar lands in the field like typed text; a
// right click marks a competition attempt invalid and valid again
Item {
    width: 800
    height: 600

    DateField {
        id: field
        x: 20
        y: 20
        text: "14.03.2007"
    }

    SignalSpy {
        id: edits
        target: field
        signalName: "textEdited"
    }

    AttemptField {
        id: attempt
        x: 20
        y: 500
    }

    TestCase {
        name: "DateField"
        when: windowShown

        function test_pickInCalendar() {
            const calendar = findChild(field, "dateCalendar")
            mouseClick(findChild(field, "calendarButton"))
            tryCompare(calendar, "opened", true)
            // Opens at the field's month
            compare(calendar.month, 2)
            compare(calendar.year, 2007)
            calendar.picked("2007-03-21")   // as a click on the 21st
            compare(field.text, "21.03.2007")
            compare(edits.count, 1)
            calendar.close()
            tryCompare(calendar, "visible", false)
        }

        function test_rightClickMarksAttemptInvalid() {
            attempt.setValue(73)
            mouseClick(attempt, 10, 10, Qt.RightButton)
            compare(attempt.value, -73)
            verify(attempt.font.strikeout)
            mouseClick(attempt, 10, 10, Qt.RightButton)
            compare(attempt.value, 73)
        }
    }
}
