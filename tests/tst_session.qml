import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 1200
    height: 900

    SessionEditor {
        id: dialog
        width: 640
        height: 880
    }

    TestCase {
        name: "SessionEditor"
        when: windowShown

        readonly property string athlete: "test_tina"
        readonly property string monday: "2026-11-09"

        function entry(i) {
            return findChild(dialog, "entry" + i)
        }

        function typeInto(item, text) {
            verify(item, "field exists")
            waitForRendering(window) // let new step boxes reach their place
            mouseClick(item)
            for (const ch of text)
                keyClick(ch)
        }

        function cleanup() {
            dialog.dirty = false
            dialog.close()
            Store.removeSession(athlete, monday, "P", 1, 2)
        }

        function test_1_createAndSave() {
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            compare(dialog.exists, false)

            // New weight exercise: focus lands in the number field.
            dialog.addEntry({ kind: 0 }, true)
            tryVerify(() => entry(0) !== null)
            const e = entry(0)
            const number = findChild(e, "exerciseField")
            tryCompare(number, "activeFocus", true)
            keyClick("8")
            compare(e.exercise, 8)
            compare(e.exerciseValid, true)

            typeInto(findChild(e, "kg0"), "13")
            // Typing into the last step adds a new empty one.
            tryVerify(() => findChild(e, "kg1") !== null)
            typeInto(findChild(e, "reps0"), "4")
            typeInto(findChild(e, "sets0"), "3")
            // Tab moves on to the next step's weight.
            keyClick(Qt.Key_Tab)
            compare(findChild(e, "kg1").activeFocus, true)
            keyClick("1"); keyClick("5")
            keyClick(Qt.Key_Tab); keyClick("3")
            keyClick(Qt.Key_Tab); keyClick("2")

            compare(e.entryStats.wh, 18)
            compare(e.entryStats.mhg, 14)
            compare(e.entryStats.bw, 15)
            compare(e.entryStats.repsSets, "3/2")
            verify(dialog.dirty)

            dialog.addEntry({ kind: 1 }, true)
            tryVerify(() => entry(1) !== null)
            typeInto(findChild(entry(1), "exerciseField"), "32")
            typeInto(findChild(entry(1), "exerciseText"), "4x8")

            dialog.addEntry({ kind: 2 }, true)
            tryVerify(() => entry(2) !== null)
            tryCompare(findChild(entry(2), "freeText"), "activeFocus", true)
            keyClick("D"); keyClick("e"); keyClick("h"); keyClick("n"); keyClick("e"); keyClick("n")

            verify(dialog.save())
            compare(dialog.dirty, false)

            const week = Store.week(athlete, monday, "P")
            compare(week.sessions.length, 1)
            const s = week.sessions[0]
            compare(s.entries.length, 3)
            compare(s.entries[0].exercise, 8)
            compare(s.entries[0].line, "18  14  15  3/2")
            compare(s.entries[0].steps.length, 2)
            compare(s.entries[1].kind, 1)
            compare(s.entries[1].exercise, 32)
            compare(s.entries[1].text, "4x8")
            compare(s.entries[2].text, "Dehnen")
            compare(week.k17, "K1-7: 18Wh / 14kg / 0,2t")
        }

        function test_2_reopenEditRemove() {
            // Prepare a stored session.
            Store.saveSession(athlete, monday, "P", {
                day: 1, number: 2, from: "15:30", to: "17:30", note: "",
                entries: [
                    { kind: 0, exercise: 8, steps: [{ kg: 12, reps: 3, sets: 3 }, { kg: 15, reps: 3, sets: 2 }] },
                    { kind: 2, text: "Dehnen" }
                ]
            })

            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            compare(dialog.exists, true)
            tryVerify(() => entry(0) !== null && entry(1) !== null)
            compare(findChild(entry(0), "kg0").text, "12")
            compare(findChild(entry(0), "sets1").text, "2")
            compare(entry(0).entryStats.wh, 15)
            compare(entry(0).entryStats.mhg, 13)

            // Change 12 kg to 13 kg, then drop the text line.
            const kg = findChild(entry(0), "kg0")
            waitForRendering(window)
            mouseClick(kg)
            keyClick(Qt.Key_A, Qt.ControlModifier)
            keyClick("1"); keyClick("3")
            compare(entry(0).entryStats.mhg, 14)

            entry(1).removeRequested()
            tryVerify(() => entry(1) === null)

            dialog.save()
            const s = Store.week(athlete, monday, "P").sessions[0]
            compare(s.entries.length, 1)
            compare(s.entries[0].steps[0].kg, 13)
            compare(s.from, "15:30")
        }

        // Saving a session with nothing in it creates none, and removes
        // the one there was; TE löschen asks on top of the open editor
        function test_5_emptySessionAndDelete() {
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            verify(!dialog.exists)
            verify(dialog.save())
            compare(dialog.dirty, false)
            verify(!Store.session(athlete, monday, "P", 1, 2).exists)

            Store.saveSession(athlete, monday, "P", { day: 1, number: 2, note: "locker", entries: [] })
            verify(Store.session(athlete, monday, "P", 1, 2).exists)
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            const before = DialogStack.open
            mouseClick(findChild(dialog, "deleteButton"))
            tryCompare(DialogStack, "open", before + 1)
            verify(dialog.visible)           // the editor stays behind the question
            keyClick(Qt.Key_Escape)          // Nein
            tryCompare(DialogStack, "open", before)
            verify(dialog.visible)

            // Emptied and saved: gone, like TE löschen
            findChild(dialog, "noteField").text = ""
            dialog.dirty = true
            verify(dialog.save())
            compare(dialog.dirty, false)
            verify(!Store.session(athlete, monday, "P", 1, 2).exists)
        }

        // An impossible time keeps the editor open and says so
        function test_6_impossibleTime() {
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            dialog.addEntry({ kind: 2, text: "locker" }, false)
            dialog.dirty = true
            findChild(dialog, "fromBox").text = "25:00"
            dialog.save()
            verify(dialog.visible)
            compare(dialog.error, "„25:00“ ist keine Uhrzeit.")
            verify(!Store.session(athlete, monday, "P", 1, 2).exists)
            findChild(dialog, "fromBox").text = "9:5"
            verify(dialog.save())
            compare(dialog.dirty, false)
            compare(Store.session(athlete, monday, "P", 1, 2).from, "09:05")
        }

        // Changes are saved when the panel closes, or another session is
        // chosen; one that cannot be saved keeps the panel where it is
        function test_3_closingAndSwitchingSave() {
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            dialog.addEntry({ kind: 2, text: "locker" }, true)
            verify(dialog.dirty)
            verify(dialog.close())
            compare(dialog.opened, false)
            compare(Store.session(athlete, monday, "P", 1, 2).entries[0].text, "locker")

            dialog.edit(athlete, monday, "P", 1, 2)
            dialog.addEntry({ kind: 2, text: "Dehnen" }, true)
            verify(dialog.edit(athlete, monday, "P", 3, 2))
            compare(dialog.day, 3)
            compare(Store.session(athlete, monday, "P", 1, 2).entries.length, 2)

            dialog.addEntry({ kind: 2, text: "Lauf" }, true)
            findChild(dialog, "fromBox").text = "25:00"
            verify(!dialog.edit(athlete, monday, "P", 1, 2))
            compare(dialog.day, 3)
            verify(dialog.error !== "")
            findChild(dialog, "fromBox").text = ""
            verify(dialog.close())
            Store.removeSession(athlete, monday, "P", 3, 2)
        }

        // "Wie Vorwoche" takes the lines of the same session last week
        function test_7_lastWeek() {
            const before = Store.addWeeks(monday, -1)
            Store.saveSession(athlete, before, "I", { day: 1, number: 2, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] }, { kind: 2, text: "Dehnen" }] })
            dialog.edit(athlete, monday, "P", 1, 2)
            const button = findChild(dialog, "lastWeekButton")
            tryVerify(() => button.visible)
            mouseClick(button)
            tryVerify(() => entry(1) !== null)
            verify(dialog.dirty)
            compare(entry(0).value().steps[0].kg, 50)
            verify(!button.visible)
            dialog.dirty = false
            Store.removeSession(athlete, before, "I", 1, 2)
        }

        function test_4_weekFiguresIncludeOtherSessions() {
            Store.saveSession(athlete, monday, "P", {
                day: 3, number: 2, entries: [
                    { kind: 0, exercise: 8, steps: [{ kg: 20, reps: 2, sets: 1 }] }
                ]
            })
            dialog.edit(athlete, monday, "P", 1, 2)
            tryCompare(dialog, "opened", true)
            dialog.addEntry({ kind: 0, exercise: 8, steps: [{ kg: 10, reps: 2, sets: 1 }] }, false)
            dialog.recalc()
            const w = dialog.weekStats["8"]
            compare(w.wh, 4)
            compare(w.bw, 20)
            compare(w.mhg, 15)
            Store.removeSession(athlete, monday, "P", 3, 2)
        }
    }
}
