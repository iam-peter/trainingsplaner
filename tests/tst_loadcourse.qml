import QtQuick
import QtTest
import Trainingsplaner

// The load chart's numbers: per week of the MAZ the ITP's target, what
// was done and what is planned, in kg or % of the MAZ target
Item {
    id: window
    width: 1400
    height: 900

    ItpModel {
        id: itp
        weeks: 3
        exercises: [1, -1]
    }

    LoadChartDialog {
        id: dialog
    }

    TestCase {
        name: "LoadCourse"
        when: windowShown

        readonly property string athlete: "test_lars"
        readonly property int editRole: Qt.UserRole + 1
        property string mazId
        property string w1
        property string w2

        function initTestCase() {
            mazId = Plan.saveMaz({ name: "Verlauf-MAZ", shortName: "VM", sex: 1, from: "10/2031", to: "12/2031" }).id
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 100, targetCleanJerk: 120,
                                  compSnatch: 80, compCleanJerk: 100 })
            w1 = Store.weekFromLabel("10/2031")
            w2 = Store.addWeeks(w1, 1)
            itp.owner = athlete
            itp.fromMonday = w1
            // Week 1: snatch target WH 10, MHG 60, BW 70, K1 target 30, high;
            // week 2: lowered
            for (const [r, c, v] of [[0, 0, "10"], [0, 1, "60"], [0, 2, "70"], [0, 3, "30"], [0, 6, "h"], [1, 6, "g"]])
                verify(itp.setData(itp.index(r, c), v, editRole))
            Store.saveSession(athlete, w1, "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }, { kg: 65, reps: 2, sets: 2 }] }] })
            Store.saveSession(athlete, w2, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 70, reps: 2, sets: 2 }] }] })
        }

        function cleanupTestCase() {
            Store.removeSession(athlete, w1, "I", 1, 1)
            Store.removeSession(athlete, w2, "P", 1, 1)
            Plan.removeMaz(mazId)
        }

        function test_course() {
            const c = Plan.loadCourse(athlete, mazId, "", 0, 1, "kg")
            compare(c.labels.length, 3)
            compare(c.labels[0], "10")
            compare(c.load[0], "h")
            compare(c.load[1], "g")
            compare(c.unit, "kg")
            compare(c.target.bw[0], 70)
            compare(c.target.mhg[0], 60)
            compare(c.target.wh[0], 30)          // the complex's own target
            compare(c.actual.bw[0], 65)
            compare(c.actual.mhg[0], 56)         // (300 + 260) / 10
            compare(c.actual.wh[0], 10)
            compare(c.actual.bw[1], undefined)
            compare(c.planned.bw[1], 70)
            compare(c.planned.wh[1], 4)
            compare(c.todayIndex, -1)            // 2031: not this year
            // The table: a header and a row per week
            compare(c.report.blocks[1].rows.length, 4)
        }

        function test_percentOfTarget() {
            const c = Plan.loadCourse(athlete, mazId, "", 0, 1, "ziel")
            compare(c.unit, "%")
            compare(c.reference, 100)
            compare(c.target.bw[0], 70)          // 70 of 100 kg
            const wk = Plan.loadCourse(athlete, mazId, "", 0, 1, "wk")
            compare(wk.reference, 80)
            compare(wk.actual.bw[0], 81)         // 65 of 80 kg, rounded
        }

        function test_dialogFindsTheMaz() {
            dialog.show(athlete, w2, "", 1)
            tryCompare(dialog, "opened", true)
            compare(dialog.mazId, mazId)
            compare(dialog.course.labels.length, 3)
            const chart = findChild(dialog.contentItem, "loadChart")
            verify(chart.count === 3)
            // The ideal line runs from the first Ist to the last target
            const id = chart.ideal("bw")
            compare(id, null)                    // one target only: no line
            dialog.close()
        }
    }
}
