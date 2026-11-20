import QtQuick
import QtTest
import Trainingsplaner

// IDA's "Min zum WoBW" in the Abschnittsanalyse: only the steps at or
// above a share of their exercise's best weight of the week count
TestCase {
    name: "WeekBest"

    property string athlete
    readonly property string monday: "2038-02-01"

    function initTestCase() {
        athlete = Store.saveAthlete({ lastName: "Bestwert", firstName: "Ben", sex: 0 })
        // Snatch, best of the week 70; a second session with 50 only
        Store.saveSession(athlete, monday, "I", { day: 1, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }, { kg: 60, reps: 2, sets: 2 },
                                            { kg: 70, reps: 1, sets: 3 }] },
            { kind: 0, exercise: 19, steps: [{ kg: 100, reps: 3, sets: 2 }] } ] })
        Store.saveSession(athlete, monday, "I", { day: 3, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 3 }] } ] })
    }

    function cleanupTestCase() {
        Store.removeAthlete(athlete)
    }

    function rows(minWeekBest, groups) {
        const r = Analysis.individual({ athleteId: athlete, mazId: "", from: "5/2038", weeks: 1, basis: "I",
                                        reference: "kg", groups: !!groups, competitionWeeks: true, summary: true,
                                        compareMazId: "", compareBasis: "I", allMaz: false, setSizes: true,
                                        minWeekBest: minWeekBest, loadExercise: 0 })
        return r
    }
    function line(report, name, label) {
        const t = report.blocks.find(b => b.kind === "table").rows.map(r => r.map(c => c.t))
        const i = t.findIndex(r => r[0] === name)
        return t.slice(i, i + 6).find(r => r[1] === label).slice(2)
    }
    function setSizes(report) {
        const i = report.blocks.findIndex(b => b.kind === "heading" && b.text.indexOf("BW je Satzgröße") === 0)
        return report.blocks.slice(i).find(b => b.kind === "table").rows.map(r => r.map(c => c.t))
    }

    function test_all() {
        const r = rows(0)
        // 6 + 4 + 3 on Monday, 9 on Wednesday
        compare(line(r, "1 Reißen WKÜ", "Wh")[0], "22")
        compare(line(r, "1 Reißen WKÜ", "Anw")[0], "2")
        verify(!r.blocks.some(b => b.kind === "note" && b.text.indexOf("Min zum WoBW") >= 0))
    }

    function test_80() {
        const r = rows(80)
        // 60 and 70 kg (56 kg and up): 4 + 3 reps, MHG (240 + 210) / 7
        compare(line(r, "1 Reißen WKÜ", "Wh")[0], "7")
        compare(line(r, "1 Reißen WKÜ", "Mhg")[0], "64")
        compare(line(r, "1 Reißen WKÜ", "BW")[0], "70")
        // Wednesday's 50 kg do not count: one session
        compare(line(r, "1 Reißen WKÜ", "Anw")[0], "1")
        // The squat against its own best: all of it
        compare(line(r, "19 Kniebeuge vorn", "Wh")[0], "6")
        verify(r.blocks.some(b => b.kind === "note" && b.text.indexOf("ab 80 % des Wochenbestwerts") >= 0))
        // The set sizes: no triple at 50 any more
        const t = setSizes(r)
        compare(t[1].slice(0, 4), ["1 Reißen WKÜ", "70", "60", ""])
    }

    function test_100andGroups() {
        compare(line(rows(100), "1 Reißen WKÜ", "Wh")[0], "3")
        // K1 measures each exercise against its own best: the 70s only
        compare(line(rows(100, true), "K1", "Wh")[0], "3")
        compare(line(rows(100, true), "K5", "Wh")[0], "6")
    }
}
