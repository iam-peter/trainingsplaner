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
    }
}
