import QtQuick
import QtTest
import Trainingsplaner

// A note per exercise line: typed in the session editor under the line,
// shown after the line's figures in the week
Item {
    id: root
    width: 1600
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    Component {
        id: editorComponent
        EntryEditor { width: 500 }
    }

    TestCase {
        name: "LineNote"
        when: windowShown

        property string athlete
        readonly property string monday: "2036-05-05"

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Notiz", firstName: "Nele", sex: 1 })
            Store.sessionsPerDay = 2
            Store.saveSession(athlete, monday, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }], note: "Technik: Zugphase" },
                { kind: 0, exercise: 19, steps: [{ kg: 80, reps: 3, sets: 3 }] } ] })
            page.athleteId = athlete
            page.variant = "P"
            page.monday = monday
        }

        function cleanupTestCase() {
            Store.removeAthlete(athlete)
        }

        function test_editor() {
            // With a note: the field shows it and value() keeps it
            const withNote = createTemporaryObject(editorComponent, root,
                { source: { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }], note: "tief" } })
            const field = findChild(withNote, "lineNote")
            tryVerify(() => field.visible)
            compare(field.text, "tief")
            compare(withNote.value().note, "tief")
            // Without: hidden until the pen is clicked
            const without = createTemporaryObject(editorComponent, root,
                { source: { kind: 0, exercise: 19, steps: [{ kg: 80, reps: 3, sets: 3 }] } })
            const empty = findChild(without, "lineNote")
            verify(!empty.visible)
            mouseClick(findChild(without, "noteButton"))
            tryVerify(() => empty.visible)
            empty.text = "breit"
            empty.textEdited()
            compare(without.value().note, "breit")
            // A free text line has none
            const free = createTemporaryObject(editorComponent, root, { source: { kind: 2, text: "Dehnen" } })
            verify(!findChild(free, "noteButton").visible)
            compare(free.value().note, "")
        }

        function test_week() {
            const cell = findChild(page, "cell1_1")
            tryVerify(() => cell && cell.filled)
            const first = findChild(findChild(cell, "line0"), "lineNote")
            verify(first.visible)
            compare(first.text, "Technik: Zugphase")
            verify(!findChild(findChild(cell, "line1"), "lineNote").visible)
            // Saved through the Store, read back
            const week = Store.week(athlete, monday, "P")
            compare(week.sessions[0].entries[0].note, "Technik: Zugphase")
        }
    }
}
