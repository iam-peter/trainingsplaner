import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// An athlete against the average of a group in the Grafik, as IDA's
// "Kader (Ø)": a Kader, a Verein or the athletes of a MAZ, without the
// athlete compared, week by week of those with a value
Item {
    width: 1300
    height: 800

    AnalysisPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "GroupAverage"
        when: windowShown

        property var ids: []
        readonly property string monday: "2033-01-03"

        function snatch(id, week, kg, reps) {
            Store.saveSession(id, Store.addWeeks(monday, week), "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: kg, reps: reps, sets: 1 }] } ] })
        }

        function initTestCase() {
            for (const name of ["Alpha", "Beta", "Gamma", "Delta"]) {
                const id = Store.saveAthlete({ lastName: "Gruppe", firstName: name, sex: 0 })
                ids.push(id)
            }
            // Three in the Kader "TK", Delta in another
            for (let i = 0; i < 3; ++i)
                verify(Store.setAthleteAttributes(ids[i], { Kader: "TK" }))
            verify(Store.setAthleteAttributes(ids[3], { Kader: "XK" }))
            // Week 1: Alpha 60, Beta 70, Gamma 80; week 2: only Beta 90
            snatch(ids[0], 0, 60, 2)
            snatch(ids[1], 0, 70, 4)
            snatch(ids[2], 0, 80, 6)
            snatch(ids[1], 1, 90, 2)
        }

        function cleanupTestCase() {
            for (const id of ids)
                Store.removeAthlete(id)
        }

        function test_1_average() {
            const p = { athleteIds: ids.slice(0, 3), exclude: ids[0], exercise: 1, volume: 1, basis: "I",
                        reference: "kg", mazId: "", from: "1/2033", weeks: 3 }
            const g = Analysis.groupSeries(p)
            // Without Alpha: Beta and Gamma, then Beta alone, then none
            compare(g.labels, ["1/2033", "2/2033", "3/2033"])
            compare(g.bw, [75, 90, undefined])
            compare(g.wh, [5, 2, undefined])
            compare(g.members, 2)
            // Nobody left out: all three
            p.exclude = ""
            compare(Analysis.groupSeries(p).bw[0], 70)
            compare(Analysis.groupSeries(p).members, 3)
            // Percent of a MAZ target: no one here has one
            p.reference = "ziel"
            compare(Analysis.groupSeries(p).members, 0)
        }

        function test_2_inTheChart() {
            page.athleteId = ids[0]
            page.show("chart")
            const tab = findChild(page, "chartTab")
            findChild(tab, "chartFrom").text = "1/2033"
            findChild(tab, "chartWeeks").value = 3
            tab.reload()
            // The groups: each Kader, then the MAZ
            const names = tab.groups.map(g => g.name)
            verify(names.indexOf("Kader TK") >= 0)
            verify(names.indexOf("Kader XK") >= 0)
            compare(tab.groups.find(g => g.name === "Kader TK").ids.length, 3)

            const box = findChild(tab, "chartGroupBox")
            box.currentIndex = names.indexOf("Kader TK")
            mouseClick(findChild(tab, "chartGroup"))
            tryVerify(() => tab.groupAverage.members === 2)
            const chart = findChild(page, "analysisChart")
            tryVerify(() => chart.lines.some(l => l.name === "BW Ø"))
            verify(chart.lines.some(l => l.name === "MHG Ø"))
            verify(chart.bars.some(b => b.name === "Wh pro TÜ Ø"))
            mouseClick(findChild(tab, "chartGroup"))
            tryVerify(() => !chart.lines.some(l => l.name === "BW Ø"))
        }
    }
}
