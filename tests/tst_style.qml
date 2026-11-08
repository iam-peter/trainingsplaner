import QtQuick
import QtTest
import Trainingsplaner

// The settings offer the installed styles, Carbon among them; choosing
// another one saves it and asks for a restart
Item {
    width: 1000
    height: 800

    SettingsDialog {
        id: settings
    }

    SignalSpy {
        id: changed
        target: settings
        signalName: "styleChanged"
    }

    TestCase {
        name: "Style"
        when: windowShown

        function test_chooseStyle() {
            const names = Store.availableStyles.map(s => s.name)
            verify(names.indexOf("Fusion") === 0, names)
            verify(names.indexOf("Carbon") > 0, names)

            Store.uiStyle = Store.activeStyle   // as after a start
            settings.open()
            tryCompare(settings, "opened", true)
            const box = findChild(settings, "styleBox")
            compare(box.currentValue, Store.uiStyle)

            const other = Store.activeStyle === "Carbon" ? "Fusion" : "Carbon"
            box.currentIndex = box.indexOfValue(other)
            settings.accept()
            compare(Store.uiStyle, other)
            compare(changed.count, 1)   // the window offers a restart

            // Choosing the style in use again needs no restart
            settings.open()
            tryCompare(settings, "opened", true)
            box.currentIndex = box.indexOfValue(Store.activeStyle)
            settings.accept()
            compare(Store.uiStyle, Store.activeStyle)
            compare(changed.count, 1)
        }
    }
}
