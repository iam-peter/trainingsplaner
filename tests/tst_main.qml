import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// The pages share one athlete: choosing one on any page shows them on all.
// A dialog blocks the window behind it.
Item {
    Component {
        id: mainComponent
        Main {}
    }

    TestCase {
        name: "SharedAthlete"
        when: windowShown

        property string second

        function initTestCase() {
            second = Store.saveAthlete({ lastName: "Zweite", firstName: "Zoe", sex: 1 })
        }

        function cleanupTestCase() {
            Store.removeAthlete(second)
        }

        function test_choosingOnOnePageSelectsEverywhere() {
            const w = createTemporaryObject(mainComponent, null)
            const pages = ["weekPage", "planningPage", "analysisPage", "competitionsPage"]
                .map(n => findChild(w, n))
            const athletes = findChild(w, "athletesPage")

            pages[2].athleteId = second   // analysis
            for (const p of pages)
                compare(p.athleteId, second, p.objectName)

            pages[0].athleteId = "test_tina"   // week plan
            for (const p of pages)
                compare(p.athleteId, "test_tina", p.objectName)

            athletes.select(second)   // athletes page
            for (const p of pages)
                compare(p.athleteId, second, p.objectName)

            // Unsaved edits on the athletes page are not replaced
            athletes.dirty = true
            pages[3].athleteId = "test_tina"
            athletes.visible = false
            athletes.visible = true
            compare(athletes.selectedId, second)
        }

        // A click on the dimmed window neither closes the dialog (losing
        // what was entered) nor reaches the page: no second dialog opens
        function test_dialogBlocksTheWindow() {
            const w = createTemporaryObject(mainComponent, null)
            w.athlete = "test_tina"
            const week = findChild(w, "weekPage")
            tryVerify(() => findChild(week, "cell1_1") !== null)
            const settings = findChild(w, "settingsDialog")
            tryVerify(() => settings.Overlay.overlay && settings.Overlay.overlay.width > 0)
            settings.open()
            tryCompare(settings, "opened", true)
            mouseClick(findChild(week, "cell1_1"), 10, 10)
            wait(300)
            verify(settings.visible)
            compare(DialogStack.open, 1)
            settings.reject()
            tryCompare(DialogStack, "open", 0)
        }
    }
}
