import QtQuick
import QtTest
import Trainingsplaner

// The welcome dialog's demo data: invented athletes with weeks around
// today and competitions, which can be removed again
Item {
    width: 900
    height: 700

    WelcomeDialog {
        id: welcome
        property string created
        onDemoCreated: (id) => created = id
    }

    HelpDialog {
        id: help
    }

    TestCase {
        name: "Welcome"
        when: windowShown

        function test_demoDataAndRemoval() {
            const before = Store.athletes.length
            welcome.open()
            tryCompare(welcome, "opened", true)
            mouseClick(findChild(welcome.contentItem, "demoButton"))
            tryCompare(welcome, "visible", false)
            compare(DialogStack.open, 0)

            const id = welcome.created
            verify(id !== "")
            verify(Store.hasDemoData)
            compare(Store.athletes.length, before + 2)
            const monday = Store.mondayOf(Store.today())
            verify(Store.week(id, monday, "P").sessions.length >= 4)
            verify(Store.week(id, Store.addWeeks(monday, -1), "I").sessions.length >= 4)
            compare(Store.week(id, monday, "I").sessions.length, 0)   // the current week is not done yet
            // Two done, with results, and two to come
            const comps = Store.competitions(id)
            compare(comps.length, 4)
            compare(comps.filter(c => c.total > 0).length, 2)
            compare(comps.filter(c => c.date > Store.today()).length, 2)

            Store.removeDemoData()
            verify(!Store.hasDemoData)
            compare(Store.athletes.length, before)
        }

        function test_helpOpensAndCloses() {
            help.open()
            tryCompare(help, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(help, "visible", false)
            verify(Glossary.explain("MHG").startsWith("MHG: "))
            verify(Glossary.group(1).indexOf("1 Reißen WKÜ") > 0)
        }
    }
}
