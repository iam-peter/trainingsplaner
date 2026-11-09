import QtQuick
import QtTest
import Trainingsplaner

// The about dialog shows the version and checks for updates; the colour
// scheme setting switches the colours while the program runs
Item {
    SystemPalette { id: systemPalette }
    width: 900
    height: 700

    AboutDialog {
        id: about
    }

    TestCase {
        name: "About"
        when: windowShown

        function cleanup() {
            about.close()
            Store.colorScheme = "system"
        }

        function test_versionAndUpdateCheck() {
            Updater.launchInstaller = false
            Updater.apiUrl = updateFixtures.newer
            about.open()
            tryCompare(about, "opened", true)
            verify(findChild(about.contentItem, "versionLabel").text.indexOf(Updater.currentVersion) > 0)
            verify(Updater.systemInfo.indexOf("Trainingsplaner " + Updater.currentVersion) === 0)
            verify(Updater.issueUrl.toString().indexOf("issues/new") > 0)

            mouseClick(findChild(about.contentItem, "checkButton"))
            tryCompare(Updater, "state", "available")
            verify(findChild(about.contentItem, "updateStatus").text.indexOf("99.0.0") >= 0)
            verify(findChild(about.contentItem, "installButton").visible)
        }

        function test_colorSchemeSwitchesAtOnce() {
            Store.colorScheme = "dark"
            compare(Store.colorScheme, "dark")
            tryVerify(() => Theme.dark)
            verify(systemPalette.window.hslLightness < 0.5)   // the widgets follow too
            Store.colorScheme = "light"
            tryVerify(() => !Theme.dark)
            verify(systemPalette.window.hslLightness > 0.5)
        }

        // The old program's colours: light, beige, yellow session boxes;
        // back to the usual ones when another scheme is chosen
        function test_classicColors() {
            const before = Store.colorScheme
            Store.colorScheme = "classic"
            verify(Store.classicColors)
            tryCompare(Theme, "cell", "#fff4bc")
            verify(!Theme.dark)
            compare(Theme.window, "#ece9d8")
            compare(systemPalette.window, "#ece9d8")   // the system dialogs too
            Store.colorScheme = "light"
            verify(!Store.classicColors)
            tryCompare(Theme, "window", "#ffffff")
            Store.colorScheme = before
        }
    }
}
