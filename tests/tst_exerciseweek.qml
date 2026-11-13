import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 1200
    height: 900

    ExerciseEditor {
        id: dialog
        x: 300
        width: 640
        height: 880
    }

    SessionCell {
        id: cell
        x: 0; y: 0; width: 200; height: 300
        visible: false
        session: ({ day: 1, number: 2, from: "15:30", note: "", entries: [
            { kind: 0, exercise: 8, line: "18  14  15  3/2" },
            { kind: 2, exercise: 0, line: "Dehnen" } ] })
    }

    SignalSpy { id: cellClicks; target: cell; signalName: "clicked" }
    SignalSpy { id: exerciseClicks; target: cell; signalName: "exerciseClicked" }

    TestCase {
        name: "SessionCell"
        when: windowShown

        function test_lineOpensExercise() {
            cell.visible = true
            waitForRendering(cell)
            // The first line (exercise 8), then the free text below it; by
            // the lines themselves, whose height depends on the style
            mouseClick(findChild(cell, "line0"))
            compare(exerciseClicks.count, 1)
            compare(exerciseClicks.signalArguments[0][0], 8)
            compare(cellClicks.count, 0)
            // Free text and empty space open the session instead
            mouseClick(findChild(cell, "line1"))
            mouseClick(cell, 100, 200)
            compare(cellClicks.count, 2)
            compare(exerciseClicks.count, 1)
            cell.visible = false
        }
    }

    TestCase {
        name: "ExerciseEditor"
        when: windowShown

        readonly property string athlete: "test_tina"
        readonly property string monday: "2026-11-16"

        function row(i) {
            return findChild(dialog, "row" + i)
        }

        function typeInto(item, text) {
            verify(item, "field exists")
            waitForRendering(window)
            mouseClick(item)
            keyClick(Qt.Key_A, Qt.ControlModifier)
            for (const ch of text)
                keyClick(ch)
        }

        function cleanup() {
            dialog.dirty = false
            dialog.close()
            for (let d = 1; d <= 7; ++d)
                for (let n = 1; n <= 3; ++n)
                    Store.removeSession(athlete, monday, "P", d, n)
        }

        function test_editMoveAddRemove() {
            Store.saveSession(athlete, monday, "P", {
                day: 1, number: 2, from: "15:30", to: "17:30", entries: [
                    { kind: 0, exercise: 8, steps: [{ kg: 12, reps: 3, sets: 3 }, { kg: 15, reps: 3, sets: 2 }] },
                    { kind: 0, exercise: 19, steps: [{ kg: 40, reps: 3, sets: 3 }] }
                ]
            })
            Store.saveSession(athlete, monday, "P", {
                day: 3, number: 2, entries: [
                    { kind: 0, exercise: 8, steps: [{ kg: 14, reps: 2, sets: 2 }] }
                ]
            })

            dialog.edit(athlete, monday, "P", 8)
            tryCompare(dialog, "opened", true)
            compare(dialog.valid, true)
            tryVerify(() => row(0) !== null && row(1) !== null)
            compare(row(2), null)
            compare(row(0).day, 1)
            compare(row(1).day, 3)
            compare(dialog.weekStats.wh, 19)

            // Monday: 12 kg -> 13 kg
            typeInto(findChild(row(0), "kg0"), "13")
            compare(row(0).rowStats.mhg, 14)

            // Wednesday's line moves to Thursday
            row(1).day = 4
            row(1).changed()

            // A new row: Saturday, 2nd session
            mouseClick(findChild(dialog, "addRow"))
            tryVerify(() => row(2) !== null)
            row(2).day = 6
            row(2).number = 2
            // The new row's first weight field has the focus already
            tryCompare(findChild(row(2), "kg0"), "activeFocus", true)
            keyClick("2"); keyClick("0")
            keyClick(Qt.Key_Tab); keyClick("2")
            keyClick(Qt.Key_Tab); keyClick("2")
            tryVerify(() => dialog.weekStats.wh === 23, 3000, "week WH " + dialog.weekStats.wh)

            verify(dialog.save())
            compare(dialog.dirty, false)

            const week = Store.week(athlete, monday, "P")
            const at = (d, n) => week.sessions.find(s => s.day === d && s.number === n)
            compare(at(1, 2).entries.length, 2)
            compare(at(1, 2).entries[0].steps[0].kg, 13)
            compare(at(1, 2).entries[1].exercise, 19)
            compare(at(3, 2), undefined)            // emptied, so removed
            compare(at(4, 2).entries[0].steps[0].kg, 14)
            compare(at(6, 2).entries[0].exercise, 8)
            compare(at(6, 2).from, "15:30")         // times of another 2nd session

            // Remove the Thursday row again
            dialog.edit(athlete, monday, "P", 8)
            tryVerify(() => row(2) !== null)
            row(1).removeRequested()
            dialog.save()
            compare(Store.week(athlete, monday, "P").sessions.find(s => s.day === 4), undefined)
        }

        function test_switchExercise() {
            dialog.edit(athlete, monday, "P", 8)
            tryCompare(dialog, "opened", true)
            compare(row(0), null)
            dialog.switchTo(32)        // a text exercise: no weight rows
            compare(dialog.valid, false)
            dialog.switchTo(19)
            compare(dialog.valid, true)
            compare(dialog.exercise, 19)
        }
    }
}
