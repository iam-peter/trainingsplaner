import QtQuick
import QtTest
import Trainingsplaner

// The update check against local copies of GitHub's answer: newer
// version found, installer downloaded and checked, damaged download
// refused
TestCase {
    name: "Updater"

    function init() {
        Updater.launchInstaller = false
        Updater.installsItself = true
    }

    function check(fixture, state) {
        Updater.apiUrl = updateFixtures[fixture]
        Updater.check()
        tryCompare(Updater, "state", state)
    }

    function test_newerVersionDownloadsAndChecks() {
        check("newer", "available")
        compare(Updater.latestVersion, "99.0.0")
        verify(Updater.notes.indexOf("Beispiel") > 0)
        Updater.install()
        tryCompare(Updater, "state", "installing")
        compare(Updater.progress, 1)
        verify(Updater.downloadedFile !== "")
    }

    function test_damagedDownloadIsRefused() {
        check("broken", "available")
        Updater.install()
        tryCompare(Updater, "state", "error")
        verify(Updater.error.indexOf("Prüfsumme") >= 0, Updater.error)
    }

    function test_sameOrOlderVersion() {
        check("same", "upToDate")
    }

    function test_unreachable() {
        check("missing", "error")
        verify(Updater.error !== "")
    }
}
