import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// Calendar entries beside the competitions: a Lehrgang over several days
// and a Diagnostik/Test on one, entered in a dialog, shown in the month
// (with a filter) and named in the week
Item {
    id: root
    width: 1600
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "Events"
        when: windowShown

        property string athlete

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Termin", firstName: "Tom", sex: 0 })
            page.athleteId = athlete
        }

        function cleanupTestCase() {
            page.showMonth(false)
            Store.removeAthlete(athlete)
        }

        function idOf(name) {
            const day = Array.from(Store.month(athlete, "2037-03-01", false).weeks).reduce((all, w) => all.concat(Array.from(w.days)), [])
                         .find(d => d.events.some(e => e.name === name))
            return day ? day.events.find(e => e.name === name).id : ""
        }

        function test_1_save() {
            compare(Store.eventKinds, ["Lehrgang", "Diagnostik/Test"])
            // What is wrong is said
            compare(Store.saveEvent({ athleteId: "", kind: 1, from: "02.03.2037" }), "Bitte einen Sportler wählen.")
            compare(Store.saveEvent({ athleteId: athlete, kind: 1, from: "05.03.2037", to: "02.03.2037" }),
                    "„bis“ liegt vor „von“.")
            compare(Store.saveEvent({ athleteId: athlete, kind: 1, from: "Montag" }), "Datum „von“ ungültig.")
            // A Lehrgang from Thursday to Tuesday, over a weekend
            compare(Store.saveEvent({ athleteId: athlete, kind: 1, from: "05.03.2037", to: "10.03.2037",
                                      title: "Kaderlehrgang", place: "Kienbaum" }), "")
            // A Diagnostik: one day, whatever "bis" says
            compare(Store.saveEvent({ athleteId: athlete, kind: 2, from: "16.03.2037", to: "20.03.2037" }), "")
            const diag = Store.event(idOf("Diagnostik/Test"))
            compare([diag.from, diag.to, diag.title], ["16.03.2037", "", "Diagnostik/Test"])
        }

        function test_2_month() {
            const days = Array.from(Store.month(athlete, "2037-03-01", false).weeks).reduce((all, w) => all.concat(Array.from(w.days)), [])
            const on = date => days.find(d => d.date === date).events
            // On each of its days, its name marked on the first
            for (const d of ["2037-03-05", "2037-03-08", "2037-03-10"])
                compare(on(d).length, 1)
            compare(on("2037-03-11").length, 0)
            compare([on("2037-03-05")[0].firstDay, on("2037-03-09")[0].firstDay], [true, false])
            compare(on("2037-03-05")[0].dateText, "05.03.–10.03.2037")
            compare(on("2037-03-16")[0].kind, 2)
        }

        function test_3_week() {
            const c = Store.weekContext(athlete, "2037-03-09")
            compare(c.events.length, 1)
            compare(c.events[0].text, "Kaderlehrgang (05.03.–10.03.2037, Kienbaum)")
            compare(Store.weekContext(athlete, "2037-03-23").events.length, 0)
        }

        function test_4_dialogAndFilter() {
            page.showMonth(true)
            page.monthDay = "2037-03-01"
            tryVerify(() => findChild(page, "monthDay2037-03-05") !== null)
            const dayCell = findChild(page, "monthDay2037-03-05")
            tryVerify(() => findChild(dayCell, "event") !== null)
            // A click opens the dialog with the entry
            const chip = findChild(dayCell, "event")
            // Laid out first
            tryVerify(() => chip.width > 0)
            mouseClick(chip)
            const dialog = findChild(page, "eventDialog")
            tryCompare(dialog, "opened", true)
            compare(findChild(dialog.contentItem, "eventTitle").text, "Kaderlehrgang")
            compare(findChild(dialog.contentItem, "eventTo").text, "10.03.2037")
            findChild(dialog.contentItem, "eventPlace").text = "Leipzig"
            mouseClick(findChild(dialog.footer, "saveEvent"))
            tryCompare(dialog, "visible", false)
            compare(Store.event(idOf("Kaderlehrgang")).place, "Leipzig")

            // The filter hides Lehrgänge in the calendar
            const lehrgang = findChild(page, "showLehrgang")
            // The dialog's dim layer gone first
            tryVerify(() => !dialog.Overlay.overlay || dialog.Overlay.overlay.children.every(c => !c.visible || c.opacity === 0))
            wait(300)
            mouseClick(lehrgang)
            verify(!lehrgang.checked)
            tryVerify(() => findChild(findChild(page, "monthDay2037-03-05"), "event") === null)
            wait(500) // not a double click
            mouseClick(lehrgang)
            verify(lehrgang.checked)
            tryVerify(() => findChild(findChild(page, "monthDay2037-03-05"), "event") !== null)

            // Removed from the dialog
            const diag = findChild(findChild(page, "monthDay2037-03-16"), "event")
            tryVerify(() => diag.width > 0)
            mouseClick(diag)
            tryCompare(dialog, "opened", true)
            const rm = findChild(dialog.footer, "removeEvent")
            wait(300)
            mouseClick(rm)
            tryCompare(dialog, "visible", false)
            compare(idOf("Diagnostik/Test"), "")
        }
    }
}
