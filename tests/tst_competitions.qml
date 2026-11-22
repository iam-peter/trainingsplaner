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

        // The norm to draw: KET 2026 NK1 or PK, or the old program's table
        function test_normChoice() {
            const year = new Date().getFullYear()
            const id = Store.saveAthlete({ lastName: "Norm", firstName: "Nora", sex: 1, born: "01.03." + (year - 20) })
            Store.saveCompetition({ athleteId: id, date: year + "-03-07", name: "DM", type: 1, bodyWeight: "60,8",
                                    snatch: [80, 0, 0], cleanJerk: [100, 0, 0] }, "", "")
            // A later date without a result yet doesn't count
            Store.saveCompetition({ athleteId: id, date: year + "-12-20", name: "Liga", type: 3 }, "", "")
            const t = Store.competitionTrend(id, year, year, 0, [0, 1, 2, 3, 4, 5, 6])
            compare(t.norms.map(n => n.key), ["nk1", "pk", "winwota"])
            compare(t.norms[0].value, 181)   // NK1, 20 years, -61
            compare(t.norms[1].value, 196)   // PK
            compare(t.norms[2].value, 0)     // no old table loaded
            verify(t.norms[0].tip.indexOf("Klasse -61") >= 0)

            page.athleteId = id
            page.reloadTrend()
            const box = findChild(page, "normBox"), check = findChild(page, "showNorm")
            compare(box.displayText, "KET NK1: 181 kg")
            verify(check.enabled)
            box.currentIndex = 1
            compare(box.displayText, "KET PK: 196 kg")
            box.currentIndex = 2
            compare(box.displayText, "WinWoTA 2005: –")
            verify(!check.enabled)
            box.currentIndex = 0
            Store.removeAthlete(id)
        }
    }
}
