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
            const tabs = settings.contentItem.children[0]
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
