import QtQuick
import QtTest
import Trainingsplaner

// The pages share one athlete: choosing one on any page shows them on all.
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
    }
}
