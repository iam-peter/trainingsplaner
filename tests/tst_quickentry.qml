import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// Quicker entry: the next weight proposed by the athlete's usual jump,
// the total reps of an AMKT text worked out, earlier lines offered
Item {
    id: window
    width: 1200
    height: 600

    readonly property string athlete: "test_quinn"
    readonly property string monday: "2026-11-09"

    Component {
        id: stepsComponent
        StepsEditor { width: 800; jump: 5 }
    }
    Component {
        id: entryComponent
        EntryEditor { width: 1100 }
    }

    TestCase {
        name: "QuickEntry"
        when: windowShown

        function typeInto(item, text) {
            verify(item, "field exists")
            waitForRendering(window)
            mouseClick(item)
            item.selectAll()
            for (const ch of text)
                keyClick(ch)
        }

        function cleanup() {
            for (const day of [1, 2, 3])
                Store.removeSession(athlete, monday, "P", day, 1)
        }

        function test_nextWeightProposed() {
            const e = createTemporaryObject(stepsComponent, window)
            typeInto(findChild(e, "kg0"), "50")
            tryVerify(() => findChild(e, "kg1") !== null)
            compare(findChild(e, "kg1").text, "55")
            // Only a proposal: not a step until it gets its reps
            compare(e.value().length, 1)

            // It follows the step before while untouched
            typeInto(findChild(e, "kg0"), "60")
            compare(findChild(e, "kg1").text, "65")

            // Reps take it; then it stays
            typeInto(findChild(e, "reps1"), "3")
            compare(e.value().length, 2)
            compare(e.value()[1].kg, 65)
            typeInto(findChild(e, "kg0"), "70")
            compare(findChild(e, "kg1").text, "65")
        }

        function test_typedWeightStays() {
            const e = createTemporaryObject(stepsComponent, window)
            typeInto(findChild(e, "kg0"), "50")
            tryVerify(() => findChild(e, "kg1") !== null)
            typeInto(findChild(e, "kg1"), "52")
            typeInto(findChild(e, "kg0"), "40")
            compare(findChild(e, "kg1").text, "52")
        }

        function test_clearingTakesProposalBack() {
            const e = createTemporaryObject(stepsComponent, window)
            typeInto(findChild(e, "kg0"), "50")
            tryVerify(() => findChild(e, "kg1") !== null)
            const kg0 = findChild(e, "kg0")
            kg0.selectAll()
            keyClick(Qt.Key_Backspace)
            compare(findChild(e, "kg1").text, "")
        }

        function test_noPlaceholderForSets() {
            const e = createTemporaryObject(stepsComponent, window)
            compare(findChild(e, "sets0").placeholderText, "")
        }

        function test_usualJumpOfTheAthlete() {
            // No history: 5 kg
            compare(Store.usualJump(athlete, monday, 1), 5)
            Store.saveSession(athlete, monday, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 40, reps: 3, sets: 2 }, { kg: 43, reps: 3, sets: 2 },
                                                { kg: 46, reps: 2, sets: 2 }, { kg: 50, reps: 1, sets: 2 }] },
                { kind: 0, exercise: 19, steps: [{ kg: 60, reps: 5, sets: 2 }, { kg: 70, reps: 5, sets: 2 }] }
            ] })
            compare(Store.usualJump(athlete, monday, 1), 3)
            compare(Store.usualJump(athlete, monday, 19), 10)
            // Another exercise without lines: the athlete's jumps overall,
            // the smaller on a tie
            compare(Store.usualJump(athlete, monday, 3), 3)
        }

        function test_amktTotalFromText() {
            const e = createTemporaryObject(entryComponent, window, { source: { kind: 1, exercise: 32 } })
            const text = findChild(e, "exerciseText")
            const total = findChild(e, "totalReps")
            typeInto(text, "4x12")
            compare(total.text, "48")
            compare(e.value().totalReps, 48)
            typeInto(text, "3x10 + 2x8")
            compare(total.text, "46")
            // "Max" gives no number: nothing filled
            typeInto(text, "4xMax")
            compare(total.text, "")
            compare(e.value().totalReps, 0)
            // Typed by hand, the total stays
            typeInto(total, "40")
            typeInto(text, "5x5")
            compare(total.text, "40")
        }

        function test_storedTotalTypedByHand() {
            const e = createTemporaryObject(entryComponent, window,
                                            { source: { kind: 1, exercise: 32, text: "4xMax", totalReps: 37 } })
            typeInto(findChild(e, "exerciseText"), "4x12")
            compare(findChild(e, "totalReps").text, "37")
        }

        function test_earlierTextsOffered() {
            Store.saveSession(athlete, monday, "P", { day: 2, number: 1, entries: [
                { kind: 1, exercise: 32, text: "4xMax", totalReps: 36 },
                { kind: 2, text: "Athletik 30 min." }
            ] })
            const e = createTemporaryObject(entryComponent, window,
                                            { source: { kind: 1, exercise: 32 }, athleteId: athlete, monday: monday })
            const text = findChild(e, "exerciseText")
            typeInto(text, "max")
            const list = findChild(text, "suggestions")
            tryVerify(() => list && list.visible && list.count === 1)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            compare(text.text, "4xMax")
            compare(findChild(e, "totalReps").text, "36")
            compare(text.activeFocus, true)
        }

        function test_earlierNoteByClick() {
            Store.saveSession(athlete, monday, "P", { day: 2, number: 1, entries: [{ kind: 2, text: "Athletik 30 min." }] })
            const e = createTemporaryObject(entryComponent, window,
                                            { source: { kind: 2 }, athleteId: athlete, monday: monday })
            const note = findChild(e, "freeText")
            typeInto(note, "ath")
            const list = findChild(note, "suggestions")
            tryVerify(() => list && list.visible && list.count === 1)
            waitForRendering(window)
            mouseClick(list.itemAtIndex(0))
            compare(note.text, "Athletik 30 min.")
            compare(e.value().text, "Athletik 30 min.")
            tryCompare(list, "visible", false)
        }

        function test_earlierStepsOffered() {
            Store.saveSession(athlete, monday, "P", { day: 3, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }, { kg: 55, reps: 2, sets: 2 }] }
            ] })
            const e = createTemporaryObject(entryComponent, window,
                                            { source: { kind: 0, exercise: 1 }, athleteId: athlete, monday: monday })
            typeInto(findChild(e, "kg0"), "5")
            const list = findChild(findChild(e, "kg0"), "suggestions")
            tryVerify(() => list && list.visible && list.count === 1)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            tryVerify(() => e.value().steps.length === 2)
            compare(e.value().steps[1].kg, 55)
            compare(e.value().steps[1].reps, 2)
        }
    }
}
