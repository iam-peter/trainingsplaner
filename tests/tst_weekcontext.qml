import QtQuick
import QtTest
import Trainingsplaner

// A week seen against last week and the ITP: per exercise line in the
// session editor, in the K1–K7 summary, and the week's place in its MAZ
Item {
    id: window
    width: 1300
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    ItpModel {
        id: itp
        weeks: 1
        exercises: [1, 19]
    }

    TestCase {
        name: "WeekContext"
        when: windowShown

        readonly property string athlete: "test_kim"
        readonly property int editRole: Qt.UserRole + 1
        property string mazId
        property string monday
        property string previous

        function initTestCase() {
            monday = Store.weekFromLabel("13/2031")
            previous = Store.addWeeks(monday, -1)
            const r = Plan.saveMaz({ name: "Kontext-MAZ", shortName: "KM", sex: 1, from: "10/2031", to: "20/2031",
                                     buildUp: "12/2031", peakPhase: "18/2031" })
            compare(r.error, "")
            mazId = r.id
            verify(Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 80, targetCleanJerk: 100 }))
            // The ITP's targets of the week: snatch and front squat, load, position
            itp.owner = athlete
            itp.fromMonday = monday
            for (const [col, v] of [[0, "20"], [1, "60"], [2, "70"], [3, "30"], [4, "90"], [5, "100"], [6, "3"], [7, "WK-2"]])
                verify(itp.setData(itp.index(0, col), v, editRole))
            // Last week: planned, and done a little differently
            Store.saveSession(athlete, previous, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 3 }] }] })
            Store.saveSession(athlete, previous, "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }, { kg: 60, reps: 2, sets: 2 }] }] })
            // This week: half the ITP's reps
            Store.saveSession(athlete, monday, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 60, reps: 5, sets: 5 }] }] })
            Store.saveCompetition({ athleteId: athlete, date: Store.addWeeks(monday, 2), name: "LM Jugend", type: 0 }, "", "")
        }

        function cleanupTestCase() {
            for (const [m, v] of [[previous, "P"], [previous, "I"], [monday, "P"]])
                Store.removeSession(athlete, m, v, 1, 1)
            Store.removeCompetition(athlete, Store.addWeeks(monday, 2), "")
            Plan.removeMaz(mazId)
            page.athleteId = ""
        }

        function test_context() {
            const c = Store.weekContext(athlete, monday)
            compare(c.maz.has, true)
            compare(c.maz.name, "Kontext-MAZ")
            compare(c.maz.week, 4)
            compare(c.maz.weeks, 11)
            compare(c.maz.phase, "Aufbauphase")
            compare(c.load, 3)
            compare(c.position, "WK-2")
            // Last week: its Ist, not its Plan
            compare(c.previous.variant, "I")
            compare(c.previous.perExercise["1"].wh, 10)
            compare(c.previous.perExercise["1"].mhg, 54)
            compare(c.previous.perExercise["1"].bw, 60)
            // The ITP: per exercise, per complex (snatch K1, squats K5), K1-7
            compare(c.target.perExercise["1"].mhg, 60)
            compare(c.target.groups[0], 20)
            compare(c.target.groups[4], 30)
            compare(c.target.k17.wh, 50)
            compare(c.target.k17.mhg, 78)
            compare(c.target.k17.bw, 100)
            compare(c.next.has, true)
            compare(c.next.name, "LM Jugend")
        }

        function test_weekShowsItsPlace() {
            page.athleteId = athlete
            page.monday = monday
            const line = findChild(page, "cycleLine")
            tryVerify(() => line.visible)
            verify(page.cycleText.indexOf("Kontext-MAZ · Aufbauphase · Woche 4 von 11") === 0)
            verify(page.nextCompetitionText.indexOf("Nächster Wettkampf: LM Jugend") === 0)
            // The summary: last week, the ITP and how far off the week is
            const cmp = findChild(page, "weekComparison")
            verify(cmp.text.indexOf("Vorwoche 12/2031 (Ist): 10Wh / 54kg") >= 0)
            verify(cmp.text.indexOf("ITP: 50Wh / 78kg") >= 0)
            verify(cmp.text.indexOf("−50 % WH") >= 0)
            compare(page.groupComparison(0), "VW 10 · ITP 20")
        }

        function test_sessionLineShowsLastWeekAndItp() {
            page.athleteId = athlete
            page.monday = monday
            page.openSession(1, 1)
            const dialog = findChild(page, "sessionDialog")
            tryCompare(dialog, "opened", true)
            const entry = findChild(dialog.contentItem, "entry0")
            tryVerify(() => entry !== null)
            const label = findChild(entry, "comparison")
            verify(label.visible)
            verify(label.text.indexOf("Vorwoche  WH 10 · MHG 54 · BW 60") === 0)
            verify(label.text.indexOf("ITP  WH 20 · MHG 60 · BW 70") > 0)
            dialog.close()
            tryCompare(dialog, "opened", false)
        }
    }
}
