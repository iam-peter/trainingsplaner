import QtQuick
import QtTest
import Trainingsplaner

TestCase {
    name: "Analysis"

    readonly property string athlete: "test_tina"
    readonly property string monday: "2029-01-01"

    function initTestCase() {
        Store.saveSession(athlete, monday, "I", { day: 1, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 60, reps: 3, sets: 2 }, { kg: 70, reps: 2, sets: 2 }] },
            { kind: 0, exercise: 19, steps: [{ kg: 90, reps: 5, sets: 1 }] } ] })
        Store.saveSession(athlete, Store.addWeeks(monday, 1), "I", { day: 2, number: 1, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 75, reps: 2, sets: 2 }] } ] })
    }

    // The texts of a report's cells, and all of its texts one per line
    function cellTexts(report) {
        const out = []
        for (const b of report.blocks)
            if (b.kind === "table")
                for (const row of b.rows)
                    for (const c of row)
                        out.push(c.t)
        return out
    }
    function allText(report) {
        return [report.title].concat(report.blocks.filter(b => b.kind !== "table").map(b => b.text))
                             .concat(cellTexts(report)).join("\n")
    }
    function tables(report) {
        return report.blocks.filter(b => b.kind === "table")
    }

    function test_individual() {
        const report = Analysis.individual({ athleteId: athlete, mazId: "", from: "1/2029", weeks: 2, basis: "I",
                                           reference: "kg", groups: false, competitionWeeks: true, summary: false,
                                           compareMazId: "", compareBasis: "I", allMaz: false, loadExercise: 1 })
        const text = allText(report)
        compare(report.title, "Abschnittsanalyse")
        verify(text.indexOf("1 Reißen WKÜ") >= 0)
        verify(text.indexOf("19 Kniebeuge vorn") >= 0)
        verify(text.indexOf("2 Wochen, 2 TE") >= 0, text.slice(0, 600))
        verify(text.indexOf("Laststufenanalyse TÜ 1") >= 0)
        verify(cellTexts(report).indexOf("14") >= 0)   // WH total of exercise 1: 10 + 4
        // The exercise's name in bold, as the first reports had it
        const first = tables(report)[0]
        compare(first.rows[1][0].t, "1 Reißen WKÜ")
        verify(first.rows[1][0].b)
    }

    function test_groupsAndSummary() {
        const report = Analysis.individual({ athleteId: athlete, from: "1/2029", weeks: 2, basis: "I", reference: "kg",
                                           groups: true, summary: true })
        const cells = cellTexts(report)
        verify(cells.indexOf("K1") >= 0)
        verify(cells.indexOf("K5") >= 0)
        verify(tables(report)[0].rows[0].every(c => c.t !== "1."))  // no weekly columns
    }

    function test_dataCheckAndSeries() {
        const report = Analysis.dataCheck({ from: "1/2029", weeks: 2, mode: 0,
                                          athletes: [{ id: athlete, displayName: "Test, Tina" }] })
        verify(cellTexts(report).indexOf("Test, Tina") >= 0)
        verify(cellTexts(report).indexOf("0/1") >= 0)
        const s = Analysis.series({ athleteId: athlete, mazId: "", from: "1/2029", weeks: 2, exercise: 1,
                                    volume: 1, basis: "I", reference: "kg" })
        compare(s.labels, ["1/2029", "2/2029"])
        compare(s.wh, [10, 4])
        compare(s.bw, [70, 75])
        const k = Analysis.series({ athleteId: athlete, from: "1/2029", weeks: 2, exercise: 1, volume: 10,
                                    basis: "I", reference: "kg" })
        compare(k.wh, [15, 4])   // K1-7: snatch + squat
    }

    function test_group() {
        const r = Plan.saveMaz({ name: "Gruppe", from: "1/2029", to: "2/2029" })
        Plan.saveMazAthlete({ mazId: r.id, athleteId: athlete, targetSnatch: 80, targetCleanJerk: 100 })
        for (const mode of [0, 1, 2]) {
            const report = Analysis.group({ mazId: r.id, mode: mode, exercise: 1, reference: "ziel" })
            verify(cellTexts(report).indexOf("Test, Tina") >= 0, "mode " + mode)
        }
        verify(cellTexts(Analysis.group({ mazId: r.id, mode: 2, exercise: 1, reference: "ziel" })).indexOf("93,8") >= 0) // 75 of 80
        Plan.removeMaz(r.id)
    }
}
