import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// "Skalieren" in ITP and RO: the chosen weeks and values of the
// exercises the grid shows, by a factor; kg to the weight step, percent
// whole
Item {
    width: 1366
    height: 860

    PlanningPage {
        id: planning
        anchors.fill: parent
        choosesAthlete: false
    }

    TestCase {
        name: "Scale"
        when: windowShown

        property string mazId
        property string athlete
        property string monday

        function initTestCase() {
            const r = Plan.saveMaz({ name: "Skalieren", sex: 0, from: "10/2034", to: "22/2034", template: "U17" })
            compare(r.error, "")
            mazId = r.id
            monday = Plan.maz(mazId).fromMonday
            athlete = Store.saveAthlete({ lastName: "Faktor", firstName: "Fritz", sex: 0, born: "01.03.2016" })
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 100, targetCleanJerk: 120 })
            verify(Plan.itpFromRo(mazId, athlete))
            planning.athleteId = athlete
        }

        function cleanupTestCase() {
            planning.athleteId = ""
            Plan.removeMaz(mazId)
            Store.removeAthlete(athlete)
        }

        function week(n) { return Store.addWeeks(monday, n - 1) }

        function openDialog() {
            const button = findChild(planning, "scaleButton")
            verify(button.enabled)
            mouseClick(button)
            const dialog = findChild(planning, "scaleDialog")
            tryCompare(dialog, "opened", true)
            return dialog
        }

        function setText(dialog, name, text) {
            const field = findChild(dialog.contentItem, name)
            field.text = text
        }

        function test_1_itp() {
            planning.showTab("itp")
            tryCompare(planning, "mazId", mazId)
            const before = Plan.itpForWeek(athlete, week(2), 1)
            // The RTK plans the WH per complex, the exercises' weights only
            compare([before.wh, before.mhg, before.bw], [0, 67, 72])
            const dialog = openDialog()
            // All weeks of the MAZ, all values, 90 %
            compare(findChild(dialog.contentItem, "scaleFrom").text, "10/2034")
            compare(findChild(dialog.contentItem, "scaleTo").text, "22/2034")
            compare(findChild(dialog.contentItem, "scaleFactor").value, 90)
            // Weeks 2 and 3, MHG and BW only
            setText(dialog, "scaleFrom", "11/2034")
            setText(dialog, "scaleTo", "12/2034")
            findChild(dialog.contentItem, "scaleWh").checked = false
            mouseClick(findChild(dialog.footer, "scaleApply"))
            tryCompare(dialog, "visible", false)

            const after = Plan.itpForWeek(athlete, week(2), 1)
            // 67 * 0.9 = 60.3 -> 60, 72 * 0.9 = 64.8 -> 65
            compare([after.wh, after.mhg, after.bw], [0, 60, 65])
            // Stoßen (in the set) too, week 1 and 4 not
            verify(Plan.itpForWeek(athlete, week(3), 3).bw < 120)
            compare(Plan.itpForWeek(athlete, week(1), 1).bw, 70)
            compare(Plan.itpForWeek(athlete, week(4), 1).bw, 77)
        }

        function test_2_checks() {
            const dialog = openDialog()
            const apply = findChild(dialog.footer, "scaleApply")
            verify(apply.enabled)
            // Outside the plan's weeks, or the wrong way round
            setText(dialog, "scaleTo", "30/2034")
            verify(!apply.enabled)
            setText(dialog, "scaleTo", "10/2034")
            setText(dialog, "scaleFrom", "12/2034")
            verify(!apply.enabled)
            setText(dialog, "scaleFrom", "10/2034")
            verify(apply.enabled)
            for (const name of ["scaleWh", "scaleMhg", "scaleBw"])
                findChild(dialog.contentItem, name).checked = false
            verify(!apply.enabled)
            dialog.close()
            tryCompare(dialog, "visible", false)
        }

        function test_3_ro() {
            // The RO in percent: the complexes' WH by 80 %, whole reps
            planning.openFramework(mazId)
            planning.setIndex = 5
            const k1 = Plan.itpForWeek(Plan.roOwner(mazId), week(1), -1).wh
            compare(k1, 70)
            const dialog = openDialog()
            verify(dialog.percent)
            findChild(dialog.contentItem, "scaleFactor").value = 80
            setText(dialog, "scaleTo", "10/2034")
            mouseClick(findChild(dialog.footer, "scaleApply"))
            tryCompare(dialog, "visible", false)
            compare(Plan.itpForWeek(Plan.roOwner(mazId), week(1), -1).wh, 56)
            compare(Plan.itpForWeek(Plan.roOwner(mazId), week(2), -1).wh, 90)
            // The snatch is not in the set: its percent stay
            compare(Plan.itpForWeek(Plan.roOwner(mazId), week(1), 1).bw, 70)
            planning.setIndex = 0
            planning.closeFramework()
        }
    }
}
