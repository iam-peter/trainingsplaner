import QtQuick
import QtTest
import Trainingsplaner

// The settings dialog keeps its size across its tabs
Item {
    width: 1000
    height: 800

    SettingsDialog {
        id: settings
    }

    TestCase {
        name: "Settings"
        when: windowShown

        // Switching tabs does not resize the dialog, in either direction
        function test_settingsKeepTheirSize() {
            // From the first tab, as a user opens them, to the taller ones
            const tabs = findChild(settings.contentItem, "settingsTabs")
            tabs.currentIndex = 0
            settings.open()
            tryCompare(settings, "opened", true)
            const heights = []
            for (const i of [0, 1, 2, 3, 0]) {
                tabs.currentIndex = i
                waitForRendering(settings.contentItem)
                heights.push(settings.height)
            }
            verify(heights.every(h => h === heights[0]), JSON.stringify(heights))
            settings.reject()
            tryCompare(settings, "visible", false)
        }

        // The DM Nachwuchs norms: AK 16-17 per weight class, AK 14 and 15
        // per kg of body weight; a changed one is kept with OK
        function test_normsByAgeGroup() {
            const tabs = findChild(settings.contentItem, "settingsTabs")
            settings.open()
            tryCompare(settings, "opened", true)
            // Normen, the last
            tabs.currentIndex = 4
            waitForRendering(settings.contentItem)
            verify(findChild(settings.contentItem, "norm16_0-65"))
            verify(!findChild(settings.contentItem, "norm15_040"))
            const age15 = findChild(settings.contentItem, "normAge15")
            tryVerify(() => age15.visible)
            mouseClick(age15)
            compare(settings.normAge, 15)
            tryVerify(() => findChild(settings.contentItem, "norm15_040") !== null)
            const field = findChild(settings.contentItem, "norm15_040")
            compare(field.value, 90)
            field.value = 100
            field.valueModified()
            settings.accept()
            tryCompare(settings, "visible", false)
            compare(Store.dmNorms.find(n => n.sex === 0 && n.ageClass === 15 && n.weightClass === "40").total, 100)
            Store.dmNorms = []
            compare(Store.dmNorms.find(n => n.sex === 0 && n.ageClass === 15 && n.weightClass === "40").total, 90)
            tabs.currentIndex = 0
        }

        // The paper is A4 unless chosen; what is no paper size reads as A4
        function test_paper() {
            compare(Store.printOptions.paper, "A4")
            Store.printOptions = { paper: "A5", landscape: true }
            compare(Store.printOptions.paper, "A5")
            compare(Store.printOptions.landscape, true)
            Store.printOptions = { paper: "B7" }
            compare(Store.printOptions.paper, "A4")
            Store.printOptions = { paper: "A4", landscape: false }
        }
    }
}
