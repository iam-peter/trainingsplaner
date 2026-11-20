import QtQuick
import QtTest
import Trainingsplaner

// The athletes shown, as a list to print or copy: born, AK, Kader,
// Verein, class and bests
Item {
    width: 1366
    height: 860

    // Reads the clipboard back, as pasting would
    TextEdit { id: pasted; visible: false }

    AthletesPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "AthleteList"
        when: windowShown

        property var ids: []

        function initTestCase() {
            const a = Store.saveAthlete({ lastName: "Liste", firstName: "Lara", sex: 1, born: "01.03.2009" })
            const b = Store.saveAthlete({ lastName: "Liste", firstName: "Leon", sex: 0, born: "02.04.2012" })
            ids = [a, b]
            verify(Store.setAthleteAttributes(a, { Kader: "LK", Verein: "AC Muster" }))
            Store.saveCompetition({ athleteId: a, date: "2024-05-04", name: "LM", type: 0, bodyWeight: "58",
                                    snatch: [60, 0, 0], cleanJerk: [75, 0, 0] }, "", "")
            Store.saveCompetition({ athleteId: a, date: "2025-06-07", name: "DM", type: 1, bodyWeight: "62,4",
                                    snatch: [66, 0, 0], cleanJerk: [72, 0, 0] }, "", "")
        }

        function cleanupTestCase() {
            for (const id of ids)
                Store.removeAthlete(id)
        }

        function rows() {
            const r = Store.athleteListReport(ids)
            return r.blocks.find(b => b.kind === "table").rows.map(row => row.map(c => c.t))
        }

        function test_report() {
            const year = Number(Store.today().slice(0, 4))
            const t = rows()
            compare(t[0], ["Name", "geb.", "AK", "Kader", "Verein", "Klasse", "Reißen", "Stoßen", "Zweikampf"])
            // Bests from all competitions, each on its own; the total's year
            const lara = t[1]
            compare(lara.slice(0, 2), ["Liste, Lara", "01.03.2009"])
            compare(lara[2], String(year - 2009))
            compare(lara.slice(3, 5), ["LK", "AC Muster"])
            compare(lara.slice(6), ["66", "75", "138 (2025)"])
            // The class of the last body weight, 62,4 kg: -69 for a woman
            compare(lara[5], "-69")
            // Without competitions: empty bests
            compare(t[2].slice(5), ["", "", "", ""])
            compare(Store.athleteListReport([]).blocks.some(b => b.text === "Keine Sportler."), true)
        }

        function test_copy() {
            // The page lists all athletes; its search narrows it
            findChild(page, "searchField").text = "Liste, L"
            tryCompare(page.shown, "length", 2)
            mouseClick(findChild(page, "copyAthleteList"))
            pasted.text = ""
            pasted.paste()
            verify(pasted.text.indexOf("Liste, Lara") >= 0, pasted.text)
            verify(pasted.text.indexOf("138 (2025)") >= 0)
            findChild(page, "searchField").text = ""
        }
    }
}
