import QtQuick
import QtTest
import Trainingsplaner

// A time typed in short forms is written out, one picked from the clock
// lands in the field like typed text
Item {
    width: 800
    height: 600

    TimeField {
        id: field
        x: 20
        y: 20
    }

    SignalSpy {
        id: edits
        target: field
        signalName: "textEdited"
    }

    TestCase {
        name: "TimeField"
        when: windowShown

        function init() {
            field.text = ""
            edits.clear()
        }

        function test_shortForms_data() {
            return [
                { tag: "hour", typed: "8", time: "08:00" },
                { tag: "digits", typed: "815", time: "08:15" },
                { tag: "four digits", typed: "1730", time: "17:30" },
                { tag: "short minute", typed: "8:5", time: "08:05" },
                { tag: "written out", typed: "06:45", time: "06:45" },
                { tag: "no hour", typed: "25", time: "25" },
                { tag: "empty", typed: "", time: "" },
            ]
        }

        function test_shortForms(data) {
            field.text = data.typed
            compare(field.time, data.time)
        }

        function test_writtenOutOnLeaving() {
            field.forceActiveFocus()
            keyClick(Qt.Key_9)
            keyClick(Qt.Key_3)
            keyClick(Qt.Key_0)
            compare(field.text, "930")
            field.focus = false
            field.editingFinished()
            compare(field.text, "09:30")
        }

        function test_pickHourThenMinute() {
            field.text = "07:30"
            const picker = findChild(field, "timePicker")
            mouseClick(findChild(field, "clockButton"))
            tryCompare(picker, "opened", true)
            // Opens at the field's time
            compare(picker.hour, 7)
            compare(picker.minute, 30)
            mouseClick(findChild(picker.contentItem, "hour18"))
            compare(field.text, "18:30")
            mouseClick(findChild(picker.contentItem, "minute45"))
            compare(field.text, "18:45")
            compare(edits.count, 2)
            tryCompare(picker, "visible", false)
        }

        function test_emptyPicksFullHour() {
            const picker = findChild(field, "timePicker")
            mouseClick(findChild(field, "clockButton"))
            tryCompare(picker, "opened", true)
            compare(picker.hour, -1)
            mouseClick(findChild(picker.contentItem, "hour6"))
            compare(field.text, "06:00")
            picker.close()
            tryCompare(picker, "visible", false)
        }
    }
}
