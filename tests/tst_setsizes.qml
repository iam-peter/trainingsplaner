import QtQuick
import QtTest
import Trainingsplaner

// The Abschnittsanalyse's "BW je Satzgröße": per exercise the heaviest
// weight in sets of 1 to 10 reps, as IDA's BW/SG
TestCase {
    name: "SetSizes"

    property string athlete
    readonly property string monday: "2031-01-06"

    function initTestCase() {
        athlete = Store.saveAthlete({ lastName: "Satz", firstName: "Sina", sex: 1 })
        Store.saveSession(athlete, monday, "I", { day: 1, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 60, reps: 3, sets: 2 }, { kg: 70, reps: 2, sets: 2 },
                                            { kg: 80, reps: 1, sets: 1 }] },
            { kind: 0, exercise: 20, steps: [{ kg: 100, reps: 5, sets: 3 }, { kg: 90, reps: 12, sets: 1 }] } ] })
        // Week 2: a heavier double; a single that failed every time
        Store.saveSession(athlete, Store.addWeeks(monday, 1), "I", { day: 2, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 72, reps: 2, sets: 2 }, { kg: 85, reps: 1, sets: 2, failed: 2 },
                                            { kg: 82, reps: 1, sets: 2, failed: 1 }] } ] })
        // The plan has its own
        Store.saveSession(athlete, monday, "P", { day: 1, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 75, reps: 1, sets: 3 }] } ] })
    }

    function cleanupTestCase() {
        Store.removeAthlete(athlete)
    }

    function report(basis, setSizes) {
        return Analysis.individual({ athleteId: athlete, mazId: "", from: "2/2031", weeks: 2, basis: basis,
                                     reference: "kg", groups: false, competitionWeeks: true, summary: true,
                                     compareMazId: "", compareBasis: "I", allMaz: false, setSizes: setSizes,
                                     loadExercise: 0 })
    }
    function table(r) {
        const i = r.blocks.findIndex(b => b.kind === "heading" && b.text.indexOf("BW je Satzgröße") === 0)
        return i >= 0 ? r.blocks.slice(i).find(b => b.kind === "table") : null
    }

    function test_ist() {
        const r = report("I", true)
        const t = table(r)
        verify(t)
        compare(t.rows[0].map(c => c.t), ["TÜ", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
        // Snatch: single 82 (85 failed every time), double 72, triple 60
        compare(t.rows[1].map(c => c.t), ["1 Reißen WKÜ", "82", "72", "60", "", "", "", "", "", "", ""])
        // Back squat: five 100; twelve reps are past the table
        compare(t.rows[2].map(c => c.t), ["20 Kniebeuge hinten", "", "", "", "", "100", "", "", "", "", ""])
        compare(t.rows.length, 3)
    }

    function test_planAndOff() {
        compare(table(report("P", true)).rows[1].map(c => c.t).slice(0, 3), ["1 Reißen WKÜ", "75", ""])
        verify(table(report("I", false)) === null)
        // The ITP has no sets
        verify(table(report("T", true)) === null)
    }
}
