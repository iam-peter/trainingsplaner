import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// A line of weight steps typed as notation, "70/3/2 80/2/2", into the
// session panel: "/" in a weight opens one field for the whole line
Item {
    id: window
    width: 1200
    height: 600

    Component {
        id: stepsComponent
        StepsEditor { width: 800; jump: 5 }
    }

    TestCase {
        name: "Notation"
        when: windowShown

        function type(text) {
            for (const ch of text)
                keyClick(ch)
        }

        function startIn(e) {
            waitForRendering(window)
            mouseClick(findChild(e, "kg0"))
        }

        function test_lineTypedAsNotation() {
            const e = createTemporaryObject(stepsComponent, window)
            startIn(e)
            type("70")
            verify(!e.notationMode)
            keyClick("/")
            verify(e.notationMode)
            const field = findChild(e, "notationField")
            compare(field.text, "70/")
            verify(field.activeFocus)
            type("3/2 80/2/2 85")
            keyClick(Qt.Key_Return)
            verify(!e.notationMode)
            compare(e.value(), [{ kg: 70, reps: 3, sets: 2, failed: 0 },
                                { kg: 80, reps: 2, sets: 2, failed: 0 },
                                { kg: 85, reps: 1, sets: 1, failed: 0 }])
            // The focus waits in the empty step after the line
            tryVerify(() => findChild(e, "kg3") !== null && findChild(e, "kg3").activeFocus)
        }

        function test_unreadableLineStays() {
            const e = createTemporaryObject(stepsComponent, window)
            startIn(e)
            keyClick("/")
            const field = findChild(e, "notationField")
            type("70/3/2 achtzig")
            verify(!e.notationValid)
            verify(field.error)
            keyClick(Qt.Key_Return)
            // Not taken: still shown, nothing changed
            verify(e.notationMode)
            compare(e.value().length, 0)
            // Esc goes back without a change
            keyClick(Qt.Key_Escape)
            verify(!e.notationMode)
            compare(e.value().length, 0)
        }

        function test_existingLineEdited() {
            const e = createTemporaryObject(stepsComponent, window, {
                initialSteps: [{ kg: 60, reps: 3, sets: 1 }, { kg: 65, reps: 2, sets: 2 }] })
            waitForRendering(window)
            // From the empty step after the line: the line so far
            mouseClick(findChild(e, "kg2"))
            type("72")
            keyClick("/")
            compare(findChild(e, "notationField").text, "60/3/1 65/2/2 72/")
            type("2/1")
            keyClick(Qt.Key_Tab)
            verify(!e.notationMode)
            compare(e.value().map(s => s.kg), [60, 65, 72])
        }

        function test_failedAttemptsInTheIst() {
            const e = createTemporaryObject(stepsComponent, window, { actual: true })
            startIn(e)
            keyClick("/")
            type("90/1/3/1")
            keyClick(Qt.Key_Return)
            compare(e.value(), [{ kg: 90, reps: 1, sets: 3, failed: 1 }])
            // In the Plan a fourth number is no step
            compare(e.parseNotation("90/1/3"), [{ kg: 90, reps: 1, sets: 3, failed: 0 }])
            e.actual = false
            compare(e.parseNotation("90/1/3/1"), null)
            // A step still being typed reads as far as it goes
            compare(e.parseNotation("70/3/2 74/1/"), [{ kg: 70, reps: 3, sets: 2, failed: 0 },
                                                      { kg: 74, reps: 1, sets: 1, failed: 0 }])
            compare(e.parseNotation("70//2"), null)
        }
    }
}
