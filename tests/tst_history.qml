import QtQuick
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 1100
    height: 800

    ExerciseWeekDialog { id: weekDialog }
    TrendChart { id: chart; width: 600; height: 300 }

    TestCase {
        name: "History"
        when: windowShown

        readonly property string athlete: "test_tina"
        // Three weeks; the middle one without exercise 13
        readonly property var mondays: ["2027-01-04", "2027-01-11", "2027-01-18"]

        function initTestCase() {
            Store.saveSession(athlete, mondays[0], "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 13, steps: [{ kg: 60, reps: 3, sets: 2 }] } ] })
            Store.saveSession(athlete, mondays[1], "P", { day: 2, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 40, reps: 2, sets: 2 }] } ] })
            Store.saveSession(athlete, mondays[2], "P", { day: 3, number: 2, entries: [
                { kind: 0, exercise: 13, steps: [{ kg: 65, reps: 3, sets: 2 }, { kg: 70, reps: 2, sets: 1 }] } ] })
        }

        function cleanupTestCase() {
            Store.removeSession(athlete, mondays[0], "P", 1, 1)
            Store.removeSession(athlete, mondays[1], "P", 2, 1)
            Store.removeSession(athlete, mondays[2], "P", 3, 2)
        }

        function test_historyNewestFirst() {
            const h = Store.exerciseHistory(athlete, mondays[2], "P", 13, 10)
            compare(h.length, 2)
            compare(h[0].week, "3/2027")
            compare(h[0].bw, 70)
            compare(h[0].steps, "65/3/2  70/2/1")
            compare(h[1].week, "1/2027")
            // Only up to the given week
            compare(Store.exerciseHistory(athlete, mondays[0], "P", 13, 10).length, 1)
        }

        function test_trendHasGaps() {
            const t = Store.exerciseTrend(athlete, mondays[2], "P", 13, 3)
            compare(t.labels, ["1/2027", "2/2027", "3/2027"])
            compare(t.wh, [6, 0, 8])
            compare(t.mhg[1], undefined)
            compare(t.bw[2], 70)
        }

        function test_regression() {
            const r = chart.regression([10, null, 30])
            fuzzyCompare(r[0], 10, 1e-9)
            fuzzyCompare(r[1], 10, 1e-9)
            compare(chart.regression([5]), null)
        }

        function test_copyPasteSteps() {
            Store.saveSession(athlete, mondays[1], "P", { day: 4, number: 1, entries: [
                { kind: 0, exercise: 13, steps: [{ kg: 50, reps: 5, sets: 1 }] } ] })
            weekDialog.edit(athlete, mondays[1], "P", 13)
            tryCompare(weekDialog, "opened", true)
            const row = findChild(weekDialog.contentItem, "row0")
            verify(row)
            row.copyRequested([{ kg: 80, reps: 1, sets: 3 }])
            compare(row.canPaste, true)
            row.pasteRequested()
            compare(row.rowStats.wh, 3)
            weekDialog.save()
            const s = Store.week(athlete, mondays[1], "P").sessions.find(x => x.day === 4)
            compare(s.entries[0].steps[0].kg, 80)
            Store.removeSession(athlete, mondays[1], "P", 4, 1)
        }
    }
}
