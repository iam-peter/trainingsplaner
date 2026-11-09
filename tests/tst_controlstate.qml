import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// Controls show the program's state, also after they were used and when
// the state changes elsewhere: the planning period, Plan/Ist and 3 TE in
// the week, the colour scheme after Abbrechen
Item {
    width: 1300
    height: 800

    PlanningPage {
        id: planning
        anchors.fill: parent
        athleteId: "test_tina"
    }

    SettingsDialog {
        id: settings
    }

    WeekPage {
        id: week
        visible: false
        width: 1300
        height: 800
        athleteId: "test_tina"
    }

    TestCase {
        name: "ControlState"
        when: windowShown

        property string mazA
        property string mazB

        function initTestCase() {
            mazA = Plan.saveMaz({ name: "Test-MAZ A", shortName: "A", sex: 1, from: "10/2029", to: "12/2029",
                                  buildUp: "10/2029", peakPhase: "12/2029" }).id
            mazB = Plan.saveMaz({ name: "Test-MAZ B", shortName: "B", sex: 1, from: "20/2029", to: "22/2029",
                                  buildUp: "20/2029", peakPhase: "22/2029" }).id
            Plan.saveMazAthlete({ mazId: mazA, athleteId: "test_tina" })
        }

        function cleanupTestCase() {
            Plan.removeMaz(mazA)
            Plan.removeMaz(mazB)
        }

        // The report: "eigener Zeitraum", to Rahmenorientierung and back
        // showed the MAZ instead of the own range
        function test_itpOwnRangeSurvivesRo() {
            planning.showTab("itp")
            // The selection row is shown with the tab: laid out with the next frame
            waitForRendering(planning)
            const box = findChild(planning, "mazBox")
            tryVerify(() => box.count > 1)
            // Choose "eigener Zeitraum" as a user does
            box.currentIndex = 0
            box.activated(0)
            compare(planning.mazId, "")
            mouseClick(findChild(planning, "roRadio"))
            compare(planning.roMode, true)
            verify(planning.mazId !== "")
            const roChoice = planning.mazId
            mouseClick(findChild(planning, "itpRadio"))
            compare(planning.roMode, false)
            compare(planning.mazId, "")                 // still the own range
            compare(box.currentIndex, 0)                // and the box shows it
            compare(box.displayText, "eigener Zeitraum")
            // Back in RO, its own choice is there again
            mouseClick(findChild(planning, "roRadio"))
            compare(planning.mazId, roChoice)
            compare(box.currentText.indexOf("Test-MAZ") >= 0 || box.currentText !== "", true)
            // The box follows a MAZ chosen from elsewhere, also after a pick
            planning.openFramework(mazB)
            compare(box.currentValue, mazB)
            mouseClick(findChild(planning, "itpRadio"))
        }

        // Abbrechen goes back to the old scheme; the radios show it
        function test_schemeRadiosAfterCancel() {
            const before = Store.colorScheme
            Store.colorScheme = "light"
            settings.open()
            tryCompare(settings, "opened", true)
            const dark = findChild(settings.contentItem, "scheme_dark")
            const light = findChild(settings.contentItem, "scheme_light")
            dark.checked = true
            dark.toggled()
            compare(Store.colorScheme, "dark")
            settings.reject()
            tryCompare(settings, "visible", false)
            compare(Store.colorScheme, "light")
            verify(light.checked)
            verify(!dark.checked)
            Store.colorScheme = before
        }

        // Plan/Ist and 3 TE follow the week also after a click, as keys and
        // a week with a third session change them without one
        function test_weekTogglesAfterClick() {
            planning.visible = false
            week.visible = true
            waitForRendering(week)
            mouseClick(findChild(week, "actualRadio"))
            compare(week.variant, "I")
            week.variant = "P"
            verify(findChild(week, "planRadio").checked)
            verify(!findChild(week, "actualRadio").checked)
            const three = findChild(week, "threeBox")
            mouseClick(three)
            const now = week.threeSessions
            week.threeSessions = !now
            compare(three.checked, !now)
            week.threeSessions = false
            week.visible = false
            planning.visible = true
        }
    }
}
