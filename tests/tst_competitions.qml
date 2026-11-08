import QtQuick
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 1200
    height: 800

    CompetitionsPage { id: page; anchors.fill: parent }

    TestCase {
        name: "Competitions"
        when: windowShown

        function test_enterAttemptsWithSpace() {
            page.athleteId = "test_tina"
            page.edit(null)
            page.edit(null)
            const s1 = findChild(page, "snatch0"), s2 = findChild(page, "snatch1")
            const c1 = findChild(page, "cleanJerk0")
            waitForRendering(page)
            mouseClick(s1); keyClick("7"); keyClick("0")
            mouseClick(s2); keyClick("7"); keyClick("3"); keyClick(Qt.Key_Space)   // invalid
            compare(s2.value, -73)
            compare(s2.font.strikeout, true)
            mouseClick(c1); keyClick("9"); keyClick("0")
            page.save()
            compare(page.error, "")
            const list = Store.competitions("test_tina")
            verify(list.length >= 1)
            const c = list.find(x => x.date === Store.parseDate(Store.formatDate(Store.today())))
            compare(c.snatch[1], -73)
            compare(c.bestSnatch, 70)
            compare(c.total, 160)
            Store.removeCompetition("test_tina", c.date, c.time)
        }
    }
}
