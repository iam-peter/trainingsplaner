import QtQuick
import QtTest
import Trainingsplaner

// "Vorwoche": the week before above the week, read only, in the same
// columns; a click on it goes there
Item {
    id: window
    width: 1300
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "PreviousWeek"
        when: windowShown

        readonly property string athlete: "test_vera"
        readonly property string monday: "2026-11-09"
        readonly property string before: "2026-11-02"

        function session(m, variant, day, number) {
            Store.saveSession(athlete, m, variant, { day: day, number: number, from: "", to: "", note: "",
                entries: [{ kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] }] })
        }

        function init() {
            Store.sessionsPerDay = 1
            Store.showPreviousWeek = true
            page.athleteId = athlete
            page.variant = "P"
            page.monday = monday
        }

        function cleanup() {
            for (const m of [monday, before])
                for (const v of ["P", "I"])
                    for (let d = 1; d <= 7; ++d)
                        for (let n = 1; n <= 3; ++n)
                            Store.removeSession(athlete, m, v, d, n)
            Store.showPreviousWeek = false
            Store.sessionsPerDay = 2
            page.monday = "2026-10-26"
        }

        function test_previousWeekAbove() {
            session(before, "P", 2, 2)
            session(before, "I", 2, 2)
            session(monday, "P", 4, 2)
            page.monday = before
            page.monday = monday
            const prev = findChild(page, "previous2_2")
            tryVerify(() => prev !== null && prev.session !== null)
            compare(findChild(page, "previousLabel").text, "Vorwoche 45/2026 · Ist")
            verify(findChild(page, "currentLabel").visible)
            // The same columns: Tuesday is wide in both, being used above
            verify(!page.narrowDay(2))
            const cur = findChild(page, "cell2_2")
            waitForRendering(page)
            compare(prev.x, cur.x)
            compare(prev.width, cur.width)
            verify(prev.y < cur.y)
            // Above: no keys, no "+"
            verify(!prev.activeFocusOnTab)
        }

        function test_planWhenNotRecorded() {
            session(before, "P", 3, 2)
            page.monday = before
            page.monday = monday
            tryCompare(findChild(page, "previousLabel"), "text", "Vorwoche 45/2026 · Plan")
        }

        function test_clickGoesThere() {
            session(before, "I", 1, 2)
            page.monday = before
            page.monday = monday
            const prev = findChild(page, "previous1_2")
            tryVerify(() => prev !== null && prev.session !== null)
            waitForRendering(page)
            mouseClick(prev, prev.width / 2, prev.height - 10)
            compare(page.monday, before)
            compare(page.variant, "I")
        }

        function test_offShowsOneWeek() {
            session(before, "I", 1, 2)
            Store.showPreviousWeek = false
            tryCompare(page, "previousRows", 0)
            verify(!findChild(page, "previousLabel").visible)
            verify(findChild(page, "previous1_2") === null)
            // The box follows the setting and sets it
            const box = findChild(page, "previousBox")
            verify(!box.checked)
            mouseClick(box)
            compare(Store.showPreviousWeek, true)
            tryVerify(() => findChild(page, "previous1_2") !== null)
        }
    }
}
