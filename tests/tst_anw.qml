import QtQuick
import QtTest
import Trainingsplaner

// IDA's "Anw" in the Abschnittsanalyse: in how many sessions an exercise
// (or a complex) is, per week, in all, per week on average and as a share
// of all sessions
TestCase {
    name: "Anw"

    property string athlete
    readonly property string monday: "2032-01-05"

    function initTestCase() {
        athlete = Store.saveAthlete({ lastName: "Anwendung", firstName: "Anna", sex: 1 })
        const lines = (ids) => ids.map(e => ({ kind: 0, exercise: e, steps: [{ kg: 50, reps: 3, sets: 2 }] }))
        // Week 1: snatch on Monday, twice on Wednesday (sessions 1 and 2),
        // clean & jerk with it on Monday; squats on Friday alone
        Store.saveSession(athlete, monday, "I", { day: 1, number: 1, entries: lines([1, 3]) })
        Store.saveSession(athlete, monday, "I", { day: 3, number: 1, entries: lines([1]) })
        Store.saveSession(athlete, monday, "I", { day: 3, number: 2, entries: lines([1]) })
        Store.saveSession(athlete, monday, "I", { day: 5, number: 1, entries: lines([19]) })
        // Week 2: snatch once in two sessions
        Store.saveSession(athlete, Store.addWeeks(monday, 1), "I", { day: 2, number: 1, entries: lines([1]) })
        Store.saveSession(athlete, Store.addWeeks(monday, 1), "I", { day: 4, number: 1, entries: lines([19]) })
    }

    function cleanupTestCase() {
        Store.removeAthlete(athlete)
    }

    function rows(groups, basis) {
        const r = Analysis.individual({ athleteId: athlete, mazId: "", from: "2/2032", weeks: 2, basis: basis || "I",
                                        reference: "kg", groups: groups, competitionWeeks: true, summary: false,
                                        compareMazId: "", compareBasis: "I", allMaz: false, loadExercise: 0 })
        const table = r.blocks.find(b => b.kind === "table")
        return table ? table.rows.map(row => row.map(c => c.t)) : []
    }
    // The Anw line of a row: the one after its name, four lines further
    function anwOf(table, name) {
        const i = table.findIndex(r => r[0] === name)
        const line = table.slice(i, i + 6).find(r => r[1] === "Anw")
        return line ? line.slice(2) : null
    }

    function test_exercises() {
        const t = rows(false)
        // Weeks 2. and 3.; all 4 in 6 sessions = 2 a week, 67 %
        compare(anwOf(t, "1 Reißen WKÜ"), ["3", "1", "4", "2,0", "67"])
        compare(anwOf(t, "3 Stoßen WKÜ"), ["1", "", "1", "0,5", "17"])
        compare(anwOf(t, "19 Kniebeuge vorn"), ["1", "1", "2", "1,0", "33"])
    }

    function test_complexes() {
        // K1: snatch and clean & jerk on Monday are one session
        compare(anwOf(rows(true), "K1"), ["3", "1", "4", "2,0", "67"])
    }

    function test_legendAndItp() {
        const r = Analysis.individual({ athleteId: athlete, mazId: "", from: "2/2032", weeks: 2, basis: "I",
                                        reference: "kg", groups: false, competitionWeeks: true, summary: false })
        verify(r.blocks.some(b => b.kind === "note" && b.text.indexOf("Anw: in wie vielen Einheiten") >= 0))
        // The ITP has no sessions
        verify(rows(false, "T").every(r => r[1] !== "Anw"))
    }
}
