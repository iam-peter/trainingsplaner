import QtQuick
import QtTest
import Trainingsplaner

// The RTK's "Tr.-Wo.", the training weeks to the main competition, in
// the ITP, the week, the month and the Belastungsverlauf, with the WK-Lage
TestCase {
    name: "Countdown"

    ItpModel { id: grid }

    property string mazId
    property string athlete
    property string monday

    function initTestCase() {
        const r = Plan.saveMaz({ name: "Countdown", sex: 0, from: "10/2038", to: "22/2038", template: "U17" })
        compare(r.error, "")
        mazId = r.id
        monday = Plan.maz(mazId).fromMonday
        athlete = Store.saveAthlete({ lastName: "Countdown", firstName: "Carla", sex: 1 })
        Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 80, targetCleanJerk: 100 })
        verify(Plan.itpFromRo(mazId, athlete))
        grid.owner = athlete
        grid.mazId = mazId
        grid.fromMonday = monday
        grid.weeks = 13
        grid.exercises = [1]
    }

    function cleanupTestCase() {
        grid.owner = ""
        Plan.removeMaz(mazId)
        Store.removeAthlete(athlete)
    }

    function last() { return grid.columnCount() - 1 }
    function at(r, c) { return grid.data(grid.index(r, c), Qt.DisplayRole) }

    function test_1_itp() {
        compare(grid.columnInfo(last()).title, "Tr.-Wo.")
        verify(grid.columnInfo(last()).readOnly)
        // The RTK's U17: its HWK in the 13th week, counted 13 down to 1
        compare(at(12, last() - 1), "HWK")
        compare([at(0, last()), at(6, last()), at(12, last())], ["13", "7", "1"])
        compare(at(13, last()), "")
        verify(!grid.setData(grid.index(0, last()), "5", Qt.UserRole + 1))

        // The main competition moved to week 11: the weeks after it count none
        verify(grid.setData(grid.index(12, last() - 1), "WK", Qt.UserRole + 1))
        verify(grid.setData(grid.index(10, last() - 1), "HWK", Qt.UserRole + 1))
        compare([at(0, last()), at(10, last()), at(11, last()), at(12, last())], ["11", "1", "", ""])
    }

    function test_2_elsewhere() {
        // The week: "Tr.-Wo. 11" beside "Woche 1 von 13"
        const context = Store.weekContext(athlete, monday)
        compare([context.maz.week, context.maz.countdown], [1, 11])
        compare(Store.weekContext(athlete, Store.addWeeks(monday, 12)).maz.countdown, 0)

        // The month: countdown and WK-Lage per week
        const weeks = Store.month(athlete, Store.addWeeks(monday, 10), false).weeks
        const hwk = weeks.find(w => w.monday === Store.addWeeks(monday, 10))
        compare([hwk.countdown, hwk.position], [1, "HWK"])
        const after = weeks.find(w => w.monday === Store.addWeeks(monday, 11))
        compare(after.countdown, 0)

        // The Belastungsverlauf: per week, and in its table
        const c = Plan.loadCourse(athlete, mazId, "", 0, 1, "kg")
        compare(c.countdown[0], 11)
        compare(c.countdown[12], undefined)
        compare(c.position[10], "HWK")
        compare(c.position[12], "WK")
        const head = c.report.blocks.find(b => b.rows !== undefined).rows[0]
        verify(JSON.stringify(head).indexOf("Tr.-Wo.") >= 0)

        // Without a MAZ, no countdown
        compare(Plan.loadCourse(athlete, "", monday, 3, 1, "kg").countdown, [undefined, undefined, undefined])
    }
}
