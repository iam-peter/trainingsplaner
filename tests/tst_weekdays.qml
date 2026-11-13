import QtQuick
import QtTest
import Trainingsplaner

// The week shows as many rows of sessions as set ("Einheiten pro Tag")
// and as the week uses; days without sessions are narrow, and the days
// scroll sideways when even that does not fit
Item {
    id: window
    width: 1300
    height: 800

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "WeekDays"
        when: windowShown

        readonly property string athlete: "test_wendy"
        readonly property string monday: "2026-11-09"
        property int perDayBefore: 2

        function cell(day, number) {
            return findChild(page, "cell" + day + "_" + number)
        }
        function head(day) {
            return findChild(page, "dayHead" + day)
        }
        function session(day, number, variant) {
            Store.saveSession(athlete, monday, variant || "P", {
                day: day, number: number, from: "", to: "", note: "",
                entries: [{ kind: 2, exercise: 0, text: "Dehnen" }]
            })
        }

        function initTestCase() {
            perDayBefore = Store.sessionsPerDay
        }

        function init() {
            window.width = 1300
            page.athleteId = athlete
            page.monday = monday
        }

        function cleanup() {
            for (const v of ["P", "I"])
                for (let d = 1; d <= 7; ++d)
                    for (let n = 1; n <= 3; ++n)
                        Store.removeSession(athlete, monday, v, d, n)
            Store.sessionsPerDay = perDayBefore
            page.monday = "2026-11-02"
            if (DialogStack.open > 0)
                findChild(page, "sessionDialog").close()
        }

        function test_rowsFollowTheSetting() {
            Store.sessionsPerDay = 1
            tryCompare(page, "rows", 1)
            verify(cell(1, 1) !== null)
            verify(cell(1, 2) === null)
            Store.sessionsPerDay = 3
            tryCompare(page, "rows", 3)
            verify(cell(1, 3) !== null)
        }

        // With two or more a day the rows are the session numbers, as in
        // WinWoTA, and a week shows every row it uses
        function test_rowsByNumber() {
            Store.sessionsPerDay = 2
            session(3, 3)
            tryCompare(page, "rows", 3)
            tryVerify(() => cell(3, 3) && cell(3, 3).session !== null)
            verify(cell(3, 1) !== null && cell(3, 1).session === null)
        }

        // One a day: each day lists its sessions from the top, so a lone
        // 2. TE (the afternoon) leaves no empty row above it
        function test_oneADayLeavesNoGap() {
            Store.sessionsPerDay = 1
            session(3, 2)
            session(5, 2)
            tryVerify(() => cell(3, 2) && cell(3, 2).session !== null)
            compare(page.rows, 1)
            compare(cell(3, 2).row, 1)
            // An empty day offers the number the week uses
            verify(cell(4, 2) !== null)
            // Two sessions on a day: two rows, the day's in order
            session(5, 3)
            tryCompare(page, "rows", 2)
            compare(cell(5, 2).row, 1)
            compare(cell(5, 3).row, 2)
            // The arrows go by rows
            page.focusSession(5, 2)
            keyClick(Qt.Key_Down)
            verify(cell(5, 3).activeFocus)
        }

        function test_planKeepsItsPlaceInIst() {
            Store.sessionsPerDay = 1
            session(4, 2, "P")
            page.variant = "I"
            tryVerify(() => cell(4, 2) !== null)
            compare(page.rows, 1)
            // And its day stays wide
            verify(!page.narrowDay(4))
            page.variant = "P"
        }

        function test_emptyDaysNarrow() {
            Store.sessionsPerDay = 1
            // A week without sessions: all days alike
            waitForRendering(page)
            compare(head(2).width, head(1).width)
            session(1, 1)
            session(5, 1)
            tryVerify(() => page.narrowDay(2))
            waitForRendering(page)
            compare(head(2).width, page.narrowWidth)
            compare(cell(2, 1).width, page.narrowWidth)
            verify(head(1).width > 3 * page.narrowWidth)
            compare(head(1).width, head(5).width)
        }

        function test_scrollsWhenTooNarrow() {
            Store.sessionsPerDay = 1
            const area = findChild(page, "gridArea")
            waitForRendering(page)
            compare(area.contentWidth, area.width)
            window.width = 700
            tryVerify(() => area.contentWidth > area.width)
            // A cell reached with the keys comes into view
            page.focusSession(7, 1)
            const c = cell(7, 1)
            tryVerify(() => c.x + c.width <= area.contentX + area.width + 1)
        }

        function test_furtherSession() {
            Store.sessionsPerDay = 1
            session(2, 1)
            tryVerify(() => page.usedDays[1])
            verify(page.canAddSession(2))
            page.addSession(2)
            compare(page.rows, 2)
            const dialog = findChild(page, "sessionDialog")
            tryCompare(dialog, "opened", true)
            compare(dialog.day, 2)
            compare(dialog.number, 2)
            dialog.close()
            // A day with three sessions takes no more
            session(2, 3)
            tryVerify(() => !page.canAddSession(2))
        }
    }
}
