import QtQuick
import QtTest
import Trainingsplaner

// Trainingszeiten show the saved times on every opening, also after a
// time was picked and the dialog cancelled; what is no time is not saved
Item {
    width: 1000
    height: 800

    SettingsDialog {
        id: settings
    }

    TestCase {
        name: "SettingsTimes"
        when: windowShown

        function test_timesAfterCancel() {
            const before = Store.sessionTimes
            Store.sessionTimes = [{ from: "06:00", to: "08:00" }, { from: "", to: "" }, { from: "", to: "" }]
            settings.open()
            tryCompare(settings, "opened", true)
            const field = findChild(settings.contentItem, "fromTime0")
            compare(field.text, "06:00")
            // As a pick from the clock does
            field.text = "07:00"
            field.textEdited()
            settings.reject()
            tryCompare(settings, "visible", false)

            settings.open()
            tryCompare(settings, "opened", true)
            compare(findChild(settings.contentItem, "fromTime0").text, "06:00")
            findChild(settings.contentItem, "toTime1").text = "25"
            settings.accept()
            tryCompare(settings, "visible", false)
            compare(Store.sessionTimes[0].from, "06:00")
            compare(Store.sessionTimes[1].to, "")
            Store.sessionTimes = before
        }
    }
}
