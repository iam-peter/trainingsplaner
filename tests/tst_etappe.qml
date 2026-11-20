import QtQuick
import QtTest
import Trainingsplaner

// The training stage (Etappe) of an athlete by age class, and the
// Datenprüfung's weeks with more or fewer sessions than it recommends
TestCase {
    name: "Etappe"

    property string athlete
    readonly property string monday: "2030-01-07"

    function initTestCase() {
        // AK 16 in 2030: ABT, 5-7 sessions a week
        athlete = Store.saveAthlete({ lastName: "Etappe", firstName: "Ella", sex: 1, born: "01.03.2014" })
        const session = (day, number) => ({ day: day, number: number, entries: [
            { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] } ] })
        // Week 1: 2 sessions done (too few); week 2: 5 planned, none done
        Store.saveSession(athlete, monday, "I", session(1, 1))
        Store.saveSession(athlete, monday, "I", session(3, 1))
        for (const day of [1, 2, 3, 4, 5])
            Store.saveSession(athlete, Store.addWeeks(monday, 1), "P", session(day, 1))
        // Week 3: 4 planned, 6 done (the Ist counts)
        for (const day of [1, 2, 3, 4])
            Store.saveSession(athlete, Store.addWeeks(monday, 2), "P", session(day, 1))
        for (const day of [1, 2, 3, 4, 5, 6])
            Store.saveSession(athlete, Store.addWeeks(monday, 2), "I", session(day, 1))
    }

    function cleanupTestCase() {
        Store.removeAthlete(athlete)
    }

    function test_athlete() {
        const a = Store.athletes.find(x => x.id === athlete)
        // This year's age class decides
        const ak = Number(Store.today().slice(0, 4)) - 2014
        const expected = ak <= 13 ? "AGA" : ak <= 15 ? "GLT" : ak <= 17 ? "ABT" : ak <= 23 ? "AST" : "HLT"
        compare(a.etappe, expected)
        verify(a.etappeText.indexOf(expected + " (") === 0)
    }

    function test_dataCheck() {
        const report = Analysis.dataCheck({ from: "2/2030", weeks: 4, mode: 0,
                                          athletes: [{ id: athlete, displayName: "Etappe, Ella" }] })
        const table = report.blocks.find(b => b.kind === "table")
        compare(table.rows[0].map(c => c.t), ["Sportler", "Etappe", "2.", "3.", "4.", "5."])
        const row = table.rows[1]
        compare(row.map(c => c.t), ["Etappe, Ella", "ABT 5–7", "0/2", "5/0", "4/6", ""])
        // Too few done; enough planned without an Ist; enough done; empty
        compare(row.slice(2).map(c => !!c.w), [true, false, false, false])
        verify(report.blocks.some(b => b.kind !== "table" && b.text.indexOf("Rot:") === 0))
    }
}
