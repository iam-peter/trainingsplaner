import QtQuick
import QtTest
import Trainingsplaner

// Session copy/paste, "Ist = Plan" and undo/redo in the store
TestCase {
    name: "Undo"

    readonly property string athlete: "test_tina"
    readonly property string monday: "2026-11-23"

    function session(variant, day, number) {
        const w = Store.week(athlete, monday, variant)
        return w.sessions.find(s => s.day === day && s.number === number) || null
    }

    function lineTexts(s) {
        return s ? s.entries.map(e => e.line).join("|") : ""
    }

    function save(day, number, text) {
        Store.saveSession(athlete, monday, "P", {
            day: day, number: number, from: "", to: "", note: "",
            entries: [{ kind: 2, exercise: 0, text: text }]
        })
    }

    function cleanup() {
        for (const v of ["P", "I"])
            for (let d = 1; d <= 7; ++d)
                for (let n = 1; n <= 3; ++n)
                    Store.removeSession(athlete, monday, v, d, n)
    }

    function test_undoRedoSaveAndDelete() {
        save(1, 1, "Dehnen")
        compare(Store.undoLabel, "Montag 1. TE speichern")
        save(1, 1, "Laufen")
        Store.removeSession(athlete, monday, "P", 1, 1)
        compare(session("P", 1, 1), null)

        const w = Store.undo()
        compare(w.monday, monday)
        compare(w.variant, "P")
        compare(lineTexts(session("P", 1, 1)), "Laufen")
        Store.undo()
        compare(lineTexts(session("P", 1, 1)), "Dehnen")
        Store.undo()
        compare(session("P", 1, 1), null)

        Store.redo()
        Store.redo()
        compare(lineTexts(session("P", 1, 1)), "Laufen")
        compare(Store.redoLabel, "Montag 1. TE löschen")

        // A new change drops what could be redone
        save(2, 1, "Rad")
        compare(Store.redoLabel, "")
    }

    function test_noChangeIsNotRecorded() {
        Store.removeSession(athlete, monday, "P", 5, 1)   // there is nothing
        save(3, 1, "Dehnen")
        const label = Store.undoLabel
        Store.removeSession(athlete, monday, "P", 6, 2)
        compare(Store.undoLabel, label)
    }

    function test_copyPasteSession() {
        save(1, 2, "Dehnen")
        Store.copySession(athlete, monday, "P", 1, 2)
        compare(Store.sessionClipboardLabel, "Montag 2. TE, Woche 48/2026 (Plan)")
        save(1, 2, "geändert")   // the copy keeps the old content
        verify(Store.pasteSession(athlete, monday, "P", 4, 1))
        compare(lineTexts(session("P", 4, 1)), "Dehnen")
        compare(Store.undoLabel, "Donnerstag 1. TE einfügen")
        Store.undo()
        compare(session("P", 4, 1), null)
    }

    function test_planToActual() {
        verify(!Store.planToActual(athlete, monday, 2, 2))   // no plan
        save(2, 2, "Dehnen")
        verify(Store.planToActual(athlete, monday, 2, 2))
        compare(lineTexts(session("I", 2, 2)), "Dehnen")
        compare(lineTexts(session("P", 2, 2)), "Dehnen")
        Store.undo()
        compare(session("I", 2, 2), null)
    }
}
