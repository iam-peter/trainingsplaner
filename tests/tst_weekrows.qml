import QtQuick
import QtTest
import Trainingsplaner

// Every row of sessions in the week is as high as the others, also when
// only one row has exercises, as in the old program
Item {
    Component { id: mainWindow; Main {} }

    TestCase {
        name: "WeekRows"
        when: windowShown

        function test_equalRows() {
            const w = createTemporaryObject(mainWindow, null)
            const athlete = Store.createDemoData()
            w.athlete = athlete
            const week = findChild(w, "weekPage")
            week.monday = Store.mondayOf(Store.today())
            const first = findChild(week, "cell1_1")
            const second = findChild(week, "cell1_2")
            tryVerify(() => second.session && second.session.entries.length > 0)
            verify(!first.session)
            waitForRendering(week)
            compare(first.height, second.height)
            Store.removeDemoData()
        }
    }
}
