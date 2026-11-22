import QtQuick
import QtTest
import Trainingsplaner

// A session dragged to another day or session of the week: moved, or
// copied with Ctrl, only onto a free place, as one step to undo
Item {
    id: window
    width: 1300
    height: 900

    Component { id: weekComponent; WeekPage { anchors.fill: parent } }

    TestCase {
        name: "DragSession"
        when: windowShown

        property int perDay

        readonly property string monday: "2031-05-05"
        readonly property var line: ({ kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] })

        function initTestCase() {
            perDay = Store.sessionsPerDay
            Store.sessionsPerDay = 2
        }
        function cleanupTestCase() {
            Store.sessionsPerDay = perDay
        }

        function test_storeMovesAndCopies() {
            const a = Store.saveAthlete({ lastName: "Zieh", firstName: "Zora", sex: 1 })
            Store.saveSession(a, monday, "P", { day: 1, number: 1, note: "Technik", entries: [line] })
            Store.saveSession(a, monday, "P", { day: 2, number: 1, entries: [line] })
            // Onto a session: refused
            verify(!Store.moveSession(a, monday, "P", 1, 1, 2, 1))
            // Moved: gone from Monday, on Wednesday's 2. TE with its note
            verify(Store.moveSession(a, monday, "P", 1, 1, 3, 2))
            verify(!Store.session(a, monday, "P", 1, 1).exists)
            const moved = Store.session(a, monday, "P", 3, 2)
            verify(moved.exists)
            compare(moved.note, "Technik")
            compare(Store.undoLabel, "Montag 1. TE verschoben nach Mittwoch 2. TE")
            // One step back
            Store.undo()
            verify(Store.session(a, monday, "P", 1, 1).exists)
            verify(!Store.session(a, monday, "P", 3, 2).exists)
            // Copied: on both days
            verify(Store.moveSession(a, monday, "P", 1, 1, 5, 1, true))
            verify(Store.session(a, monday, "P", 1, 1).exists)
            verify(Store.session(a, monday, "P", 5, 1).exists)
            Store.removeAthlete(a)
        }

        function drag(page, from, to, modifiers) {
            const src = findChild(page, from), dst = findChild(page, to)
            verify(src && dst)
            waitForRendering(page)
            mousePress(src, 20, 30)
            mouseMove(src, 40, 40)
            const p = dst.mapToItem(src, dst.width / 2, dst.height / 2)
            mouseMove(src, p.x, p.y)
            mouseRelease(src, p.x, p.y, Qt.LeftButton, modifiers || Qt.NoModifier)
        }

        function test_dragInTheWeek() {
            const a = Store.saveAthlete({ lastName: "Zieh", firstName: "Zeno", sex: 0 })
            Store.saveSession(a, monday, "P", { day: 1, number: 1, entries: [line] })
            Store.saveSession(a, monday, "P", { day: 3, number: 1, entries: [line] })
            const page = createTemporaryObject(weekComponent, window, { athleteId: a })
            page.monday = monday
            tryVerify(() => findChild(page, "cell1_1") && findChild(page, "cell1_1").filled)

            // Shown while dragging: the free place marked, the label beside
            const src = findChild(page, "cell1_1"), dst = findChild(page, "cell1_2")
            waitForRendering(page)
            mousePress(src, 20, 30)
            mouseMove(src, 40, 40)
            verify(src.dragged)
            const p = dst.mapToItem(src, dst.width / 2, dst.height / 2)
            mouseMove(src, p.x, p.y)
            verify(dst.dropTarget)
            verify(findChild(page, "dragLabel").visible)
            mouseRelease(src, p.x, p.y)
            tryVerify(() => Store.session(a, monday, "P", 1, 2).exists)
            verify(!Store.session(a, monday, "P", 1, 1).exists)
            verify(!findChild(page, "dragLabel").visible)
            // The drop opened nothing
            verify(!page.isEdited(1, 2))

            // Onto Wednesday's session: nothing happens
            drag(page, "cell1_2", "cell3_1")
            verify(Store.session(a, monday, "P", 1, 2).exists)

            // With Ctrl: a copy
            drag(page, "cell1_2", "cell5_1", Qt.ControlModifier)
            tryVerify(() => Store.session(a, monday, "P", 5, 1).exists)
            verify(Store.session(a, monday, "P", 1, 2).exists)
            Store.removeAthlete(a)
        }
    }
}
