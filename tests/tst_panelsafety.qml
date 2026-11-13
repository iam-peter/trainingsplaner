import QtQuick
import QtTest
import Trainingsplaner

// What the session panel holds is never written back over a change made
// elsewhere while it was open: the grid, the menu and undo save it first,
// and the week's note is saved only when it was edited
Item {
    id: window
    width: 1400
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "PanelSafety"
        when: windowShown

        readonly property string athlete: "test_paula"
        readonly property string monday: "2026-11-16"

        function init() {
            Store.sessionsPerDay = 2
            Store.saveSession(athlete, monday, "P", { day: 1, number: 2, note: "alt", entries: [
                { kind: 0, exercise: 8, steps: [{ kg: 12, reps: 3, sets: 3 }] }] })
            page.athleteId = athlete
            page.monday = monday
        }

        function cleanup() {
            page.closePanel()
            for (const d of [1, 2, 3])
                Store.removeSession(athlete, monday, "P", d, 2)
            Store.saveWeekNote(athlete, monday, "P", "", false)
            page.monday = "2026-11-09"
        }

        function editNote(text) {
            const editor = findChild(page, "sessionEditor")
            findChild(editor, "noteField").text = text
            verify(editor.dirty)
        }

        // Removing the session the panel holds with changes: it stays gone
        function test_removeWhileEdited() {
            page.openSession(1, 2)
            editNote("neu")
            page.askRemoveSession(1, 2)
            const confirm = findChild(page, "removeConfirm")
            tryCompare(confirm, "opened", true)
            confirm.accept()
            tryCompare(confirm, "visible", false)
            verify(page.closePanel())
            verify(!Store.session(athlete, monday, "P", 1, 2).exists)
        }

        // Undo with changes in the panel takes them back, and the panel
        // does not write them again later
        function test_undoWhileEdited() {
            page.openSession(1, 2)
            editNote("neu")
            page.undo()
            const editor = findChild(page, "sessionEditor")
            verify(!editor.dirty)
            verify(page.closePanel())
            compare(Store.session(athlete, monday, "P", 1, 2).note, "alt")
        }

        // A reload is no edit of the note field, even with the focus there
        function test_reloadIsNoEdit() {
            page.openSession(1, 2)
            const editor = findChild(page, "sessionEditor")
            findChild(editor, "noteField").forceActiveFocus()
            editor.reload()
            verify(!editor.dirty)
        }

        // The week's note changed elsewhere (an import): the reload shows
        // it rather than writing the old one back
        function test_weekNoteFollows() {
            Store.saveWeekNote(athlete, monday, "P", "von woanders", false)
            page.reload()
            compare(Store.week(athlete, monday, "P").note, "von woanders")
            compare(page.weekData.note, "von woanders")
        }

        // Erfassung TÜ saved twice without closing: a new line once
        function test_exerciseSavedTwice() {
            page.openExercise(8)
            const editor = findChild(page, "exerciseEditor")
            tryCompare(editor, "opened", true)
            editor.addRow({ origIndex: -1, day: 2, number: 2, steps: [{ kg: 20, reps: 3, sets: 1, failed: 0 }] }, false)
            editor.markChanged()
            verify(editor.save())
            editor.markChanged()
            verify(editor.save())
            const s = Store.session(athlete, monday, "P", 2, 2)
            compare(s.entries.filter(e => e.exercise === 8).length, 1)
        }
    }
}
