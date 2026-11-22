import QtQuick
import QtTest
import Trainingsplaner

// An open session taken over as Ist from the month; the athlete list
// with AK, Kader and Verein under the name; the phone on one line
Item {
    id: window
    width: 1400
    height: 900

    Component { id: weekComponent; WeekPage { anchors.fill: parent } }
    Component { id: athletesComponent; AthletesPage { anchors.fill: parent } }

    TestCase {
        name: "MonthList"
        when: windowShown

        function test_openSessionTakenInTheMonth() {
            const a = Store.saveAthlete({ lastName: "Monat", firstName: "Mila", sex: 1 })
            const monday = "2020-03-02"
            Store.saveSession(a, monday, "P", { day: 3, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 60, reps: 3, sets: 2 }] }] })
            const page = createTemporaryObject(weekComponent, window, { athleteId: a })
            page.showMonth(true)
            // (the view is kept: it may have been the month already)
            page.monthDay = "2020-03-04"
            const view = findChild(page, "monthView")
            let area = null
            tryVerify(() => {
                const day = findChild(view, "monthDay2020-03-04")
                area = day ? findChild(day, "takeOpen") : null
                return area !== null && area.enabled
            })
            waitForRendering(view)
            mouseClick(area)
            tryVerify(() => Store.session(a, monday, "I", 3, 1).exists)
            page.showMonth(false)
            Store.removeAthlete(a)
        }

        function test_athleteListDetails() {
            const year = new Date().getFullYear()
            const a = Store.saveAthlete({ lastName: "Liste", firstName: "Lea", sex: 1, born: "01.03." + (year - 16) })
            Store.setAthleteAttributes(a, { Kader: "LK", Verein: "SV Muster" })
            const page = createTemporaryObject(athletesComponent, window, { startId: a })
            const list = findChild(page, "athleteList")
            let details = null
            tryVerify(() => {
                details = findChildren(list, "athleteDetails").find(d => d.text.indexOf("AK 16") === 0)
                return details !== undefined
            })
            compare(details.text, "AK 16  ·  LK  ·  SV Muster")
            Store.removeAthlete(a)
        }

        function test_phoneOnOneLine() {
            const a = Store.saveAthlete({ lastName: "Ruf", firstName: "Rita", sex: 1, phone: "0123 456\n0170 999" })
            const page = createTemporaryObject(athletesComponent, window, { startId: a })
            compare(findChild(page, "phoneField").text, "0123 456, 0170 999")
            Store.removeAthlete(a)
        }

        function findChildren(parent, name) {
            const found = []
            const visit = (item) => {
                if (item.objectName === name)
                    found.push(item)
                for (const c of item.children)
                    visit(c)
                if (item.contentItem && item.contentItem !== item && item.contentItem.parent !== item)
                    visit(item.contentItem)
            }
            visit(parent)
            return found
        }
    }
}
