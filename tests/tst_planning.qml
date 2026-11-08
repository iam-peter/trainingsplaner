import QtQuick
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 1200
    height: 800

    ItpModel {
        id: model
        weeks: 3
        exercises: [1, -2]
    }

    TestCase {
        name: "Planning"
        when: windowShown

        readonly property int editRole: Qt.UserRole + 1

        function test_mazAndRoToItp() {
            const r = Plan.saveMaz({ name: "Test-MAZ", shortName: "T", sex: 1, from: "10/2028", to: "12/2028",
                                     buildUp: "10/2028", peakPhase: "12/2028" })
            compare(r.error, "")
            const id = r.id
            compare(Plan.maz(id).weeks, 3)
            verify(Plan.saveMaz({ name: "", from: "1/2028", to: "2/2028" }).error !== "")
            verify(Plan.saveMazAthlete({ mazId: id, athleteId: "test_tina", targetSnatch: 80, targetCleanJerk: 100 }))
            compare(Plan.mazAthletes(id)[0].targetSnatch, 80)

            // Framework plan through the grid model: snatch at 80 % in week 1
            model.owner = Plan.roOwner(id)
            model.mazId = id
            model.fromMonday = Plan.mondayFromLabel("10/2028")
            compare(model.percent, true)
            compare(model.rowCount(), 4)           // 3 weeks + average
            compare(model.columnCount(), 2 * 3 + 2)
            compare(model.rowLabel(0), "10/2028 A")
            compare(model.rowLabel(2), "12/2028 L")
            verify(model.setData(model.index(0, 0), "30", editRole))   // WH
            verify(model.setData(model.index(0, 1), "80", editRole))   // MHG %
            verify(model.setData(model.index(1, 0), "20", editRole))
            verify(model.setData(model.index(0, 6), "3", editRole))    // load
            verify(model.setData(model.index(0, 7), "WK", editRole))   // position
            compare(model.data(model.index(3, 0), Qt.DisplayRole), "25")   // average WH
            model.averageAllWeeks = true
            compare(model.data(model.index(3, 0), Qt.DisplayRole), "17")   // 50 / 3

            verify(Plan.itpFromRo(id, "test_tina"))
            model.owner = "test_tina"
            compare(model.percent, false)
            compare(model.data(model.index(0, 1), Qt.DisplayRole), "65")   // 80 % of 80 kg = 64 -> 65
            compare(model.data(model.index(0, 7), Qt.DisplayRole), "WK")

            const itp = Plan.itpForWeek("test_tina", Plan.mondayFromLabel("10/2028"), 1)
            verify(itp.has)
            compare(itp.mhg, 65)

            verify(Plan.removeMaz(id))
        }

        function test_plannedSteps() {
            const monday = Plan.mondayFromLabel("20/2028")
            compare(Plan.setPlannedSteps("test_tina", 3, monday, "80/3/2 85/3"), "")
            verify(Plan.setPlannedSteps("test_tina", 3, monday, "achtzig") !== "")
            const rows = Plan.plannedSteps("test_tina", 3, monday, 2)
            compare(rows.length, 2)
            compare(rows[0].text, "80/3/2 85/3/1")
            compare(rows[0].wh, 9)
            compare(rows[1].text, "")
            compare(Plan.setPlannedSteps("test_tina", 3, monday, ""), "")
            compare(Plan.plannedSteps("test_tina", 3, monday, 1)[0].text, "")
        }
    }
}
