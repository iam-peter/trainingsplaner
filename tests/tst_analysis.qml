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

    function test_individual() {
        const html = Analysis.individual({ athleteId: athlete, mazId: "", from: "1/2029", weeks: 2, basis: "I",
                                           reference: "kg", groups: false, competitionWeeks: true, summary: false,
                                           compareMazId: "", compareBasis: "I", allMaz: false, loadExercise: 1 })
        verify(html.indexOf("Abschnittsanalyse") >= 0)
        verify(html.indexOf("1 Reißen WKÜ") >= 0)
        verify(html.indexOf("19 Kniebeuge vorn") >= 0)
        verify(html.indexOf("2 Wochen, 2 TE") >= 0, html.slice(0, 600))
        verify(html.indexOf("Laststufenanalyse TÜ 1") >= 0)
        verify(html.indexOf(">14<") >= 0)   // WH total of exercise 1: 10 + 4
    }

    function test_groupsAndSummary() {
        const html = Analysis.individual({ athleteId: athlete, from: "1/2029", weeks: 2, basis: "I", reference: "kg",
                                           groups: true, summary: true })
        verify(html.indexOf(">K1<") >= 0 || html.indexOf("K1</b>") >= 0)
        verify(html.indexOf(">K5<") >= 0 || html.indexOf("K5</b>") >= 0)
        verify(html.indexOf("1.</th>") < 0)  // no weekly columns
    }

    function test_dataCheckAndSeries() {
        const html = Analysis.dataCheck({ from: "1/2029", weeks: 2, mode: 0,
                                          athletes: [{ id: athlete, displayName: "Test, Tina" }] })
        verify(html.indexOf("Test, Tina") >= 0)
        verify(html.indexOf("0/1") >= 0)
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
            const html = Analysis.group({ mazId: r.id, mode: mode, exercise: 1, reference: "ziel" })
            verify(html.indexOf("Test, Tina") >= 0, "mode " + mode)
        }
        verify(Analysis.group({ mazId: r.id, mode: 2, exercise: 1, reference: "ziel" }).indexOf("93,8") >= 0) // 75 of 80
        Plan.removeMaz(r.id)
    }
}
