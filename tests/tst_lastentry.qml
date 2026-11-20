import QtQuick
import QtTest
import Trainingsplaner

// "Letzter Eintrag": a click (or Ctrl+End) shows the latest week with
// sessions of the variant shown, in the month view its month
Item {
    width: 1366
    height: 860

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "LastEntry"
        when: windowShown

        property string athlete

        function session(monday, variant) {
            Store.saveSession(athlete, monday, variant, { day: 2, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 40, reps: 3, sets: 2 }] }] })
        }

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Letzte", firstName: "Lea", sex: 1 })
            compare(Store.lastEntryWeek(athlete, "P"), "")
            // Done until week 10, planned until week 14 of 2035
            session("2035-02-26", "I")
            session("2035-03-05", "I")
            session("2035-03-05", "P")
            session("2035-04-02", "P")
            page.athleteId = athlete
            page.monday = "2026-11-09"
        }

        function cleanupTestCase() {
            Store.removeAthlete(athlete)
        }

        function test_1_store() {
            compare(Store.lastEntryWeek(athlete, "P"), "2035-04-02")
            compare(Store.lastEntryWeek(athlete, "I"), "2035-03-05")
            compare(Store.lastEntryWeek("", "P"), "")
        }

        function test_2_button() {
            const button = findChild(page, "lastEntryButton")
            verify(button.enabled)
            page.variant = "P"
            mouseClick(button)
            compare(page.monday, "2035-04-02")
            // The Ist: its own last week
            page.variant = "I"
            page.monday = "2026-11-09"
            mouseClick(button)
            compare(page.monday, "2035-03-05")
        }

        function test_3_shortcut() {
            page.variant = "P"
            page.monday = "2026-11-09"
            page.forceActiveFocus()
            keyClick(Qt.Key_End, Qt.ControlModifier)
            tryCompare(page, "monday", "2035-04-02")
        }

        // At 1366 px the bar fits: its right buttons as icons only
        function test_5_barFits() {
            const bar = findChild(page, "weekBar")
            verify(page.compactBar)
            verify(bar.implicitWidth <= bar.width, bar.implicitWidth + " > " + bar.width)
            compare(findChild(page, "copyWeekButton").text, "")
            compare(findChild(page, "copyWeekButton").toolTip, "Woche kopieren")
        }

        function test_4_month() {
            page.variant = "P"
            page.showMonth(true)
            page.monthDay = "2026-11-14"
            mouseClick(findChild(page, "lastEntryButton"))
            compare(page.monthDay, "2035-04-02")
            page.showMonth(false)
        }
    }
}
