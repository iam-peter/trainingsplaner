import QtQuick
import QtTest
import Trainingsplaner

// What the panel beside the week changes is marked in the week: the
// session it edits, or the lines of the exercise Erfassung TÜ edits
Item {
    id: window
    width: 1400
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "PanelLink"
        when: windowShown

        readonly property string athlete: "test_lina"
        readonly property string monday: "2026-11-09"

        function cell(day, number) {
            return findChild(page, "cell" + day + "_" + number)
        }

        function init() {
            Store.sessionsPerDay = 2
            Store.saveSession(athlete, monday, "P", { day: 1, number: 2, entries: [
                { kind: 0, exercise: 8, steps: [{ kg: 12, reps: 3, sets: 3 }] },
                { kind: 0, exercise: 19, steps: [{ kg: 40, reps: 3, sets: 3 }] }] })
            Store.saveSession(athlete, monday, "P", { day: 3, number: 2, entries: [
                { kind: 0, exercise: 8, steps: [{ kg: 14, reps: 2, sets: 2 }] }] })
            page.athleteId = athlete
            page.monday = monday
        }

        function cleanup() {
            page.closePanel()
            for (const d of [1, 3])
                Store.removeSession(athlete, monday, "P", d, 2)
            page.monday = "2026-11-02"
        }

        // With the panel open in a small window, the complexes take more
        // rows rather than run into each other
        function test_summaryWrapsWhenNarrow() {
            window.width = 1000
            page.openSession(1, 2)
            const grid = findChild(page, "groupGrid")
            tryVerify(() => grid.columns < 7)
            waitForRendering(page)
            for (let g = 1; g <= 7; ++g)
                verify(findChild(grid, "group" + g).width + 1 >= grid.cellMinimum, "K" + g)
            page.closePanel()
            window.width = 1400
            tryCompare(grid, "columns", 7)
        }

        function test_sessionPanelMarksItsCell() {
            page.openSession(1, 2)
            verify(cell(1, 2).selected)
            verify(!cell(3, 2).selected)
            compare(page.editedExercise, 0)
            compare(findChild(page, "sessionEditor").visible, true)
        }

        function test_exercisePanelMarksItsLines() {
            const line = (d, i) => findChild(cell(d, 2), "line" + i)
            tryVerify(() => line(1, 1) !== null)
            waitForRendering(page)
            mouseClick(line(1, 0))       // exercise 8 on Monday
            const editor = findChild(page, "exerciseEditor")
            tryCompare(editor, "opened", true)
            compare(editor.exercise, 8)
            compare(page.editedExercise, 8)
            // Its lines marked in every session, the others faded
            verify(line(1, 0).marked)
            verify(!line(1, 1).marked)
            compare(line(1, 1).opacity, 0.35)
            verify(line(3, 0).marked)
            // Under the pointer, a row marks its session
            const row = findChild(editor, "row1")
            tryVerify(() => row !== null)
            waitForRendering(page)
            mouseMove(row, 20, 10)
            tryVerify(() => cell(3, 2).selected)
            verify(!cell(1, 2).selected)
            // A session opened from the week closes it, saved
            page.openSession(3, 2)
            compare(editor.opened, false)
            compare(page.editedExercise, 0)
            compare(line(1, 1).opacity, 1)
            verify(cell(3, 2).selected)
        }
    }
}
