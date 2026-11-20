import QtQuick
import QtTest
import Trainingsplaner

// A colour per complex on the lines of the week, the K boxes below as
// their legend, and a bar by complex for each session of the month
Item {
    width: 1600
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "GroupColors"
        when: windowShown

        property string athlete
        readonly property string monday: "2036-03-03"

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Farbe", firstName: "Fiona", sex: 1 })
            Store.sessionsPerDay = 2
            Store.saveSession(athlete, monday, "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] },     // K1: 6
                { kind: 0, exercise: 19, steps: [{ kg: 80, reps: 3, sets: 3 }] },    // K5: 9
                { kind: 1, exercise: 33, text: "3x8", totalReps: 24 },               // AMKT
                { kind: 2, text: "Dehnen" } ] })
            page.athleteId = athlete
            page.variant = "I"
            page.monday = monday
        }

        function cleanupTestCase() {
            Store.removeAthlete(athlete)
        }

        function test_palette() {
            compare(Theme.groupColor(1), "#dc2626")
            compare(Theme.groupColor(7), "#7c3aed")
            compare(Theme.groupColor(8), Theme.groupColor(9))
            compare(Theme.groupColor(0), "#00000000")
        }

        function test_week() {
            const cell = findChild(page, "cell1_1")
            tryVerify(() => cell && cell.filled)
            const stripes = []
            for (let i = 0; i < 4; ++i) {
                const line = findChild(cell, "line" + i)
                const stripe = findChild(line, "groupStripe")
                stripes.push(stripe.visible ? String(stripe.color) : "")
            }
            // K1, K5, AMKT grey; the free text has none
            compare(stripes, ["#dc2626", "#0d9488", "#94a3b8", ""])
            // The K boxes below in the same colours
            compare(String(findChild(page, "groupColor1").color), "#dc2626")
            compare(String(findChild(page, "groupColor5").color), "#0d9488")
        }

        function test_month() {
            const month = Store.month(athlete, monday, false)
            const day = month.weeks.find(w => w.monday === monday).days[0]
            compare(day.sessions[0].groups, [6, 0, 0, 0, 9, 0, 0])
        }
    }
}
