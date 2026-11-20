import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// Quick ranges up to this week (1, 2, 4 weeks; 1, 3, 6 months) in the
// analyses, and Ist and Plan in one chart, as IDA has them
Item {
    width: 1300
    height: 800

    QuickRanges {
        id: ranges
        property var last: null
        onPicked: (from, weeks) => last = { from: from, weeks: weeks }
    }

    AnalysisPage {
        id: page
        y: 60
        width: parent.width
        height: parent.height - 60
        athleteId: athlete
    }

    property string athlete: "test_quick"

    TestCase {
        name: "QuickRanges"
        when: windowShown

        readonly property string thisMonday: Store.mondayOf(Store.today())

        function test_1_ranges() {
            mouseClick(findChild(ranges, "weeks4"))
            compare(ranges.last.from, Store.weekLabel(Store.addWeeks(thisMonday, -3)))
            compare(ranges.last.weeks, 4)
            mouseClick(findChild(ranges, "weeks1"))
            compare(ranges.last.from, Store.weekLabel(thisMonday))
            compare(ranges.last.weeks, 1)
            // Three months: the weeks from the one three months back on
            mouseClick(findChild(ranges, "months3"))
            verify(ranges.last.weeks >= 13 && ranges.last.weeks <= 15, ranges.last.weeks)
            compare(ranges.last.from, Store.weekLabel(Store.addWeeks(thisMonday, -(ranges.last.weeks - 1))))
            // The range shown is marked
            ranges.fromLabel = ranges.last.from
            ranges.weeks = ranges.last.weeks
            verify(findChild(ranges, "months3").checked)
            verify(!findChild(ranges, "weeks4").checked)
            // A chart needs two weeks: "1" gives two
            ranges.minimumWeeks = 2
            mouseClick(findChild(ranges, "weeks1"))
            compare(ranges.last.weeks, 2)
            compare(ranges.last.from, Store.weekLabel(Store.addWeeks(thisMonday, -1)))
        }

        function test_2_inTheAnalysis() {
            page.show("individual")
            const r = findChild(page, "individualRanges")
            mouseClick(findChild(r, "weeks2"))
            const report = findChild(page, "individualReport")
            tryVerify(() => JSON.stringify(report.report).indexOf(Store.weekLabel(Store.addWeeks(thisMonday, -1))) >= 0)
            verify(findChild(r, "weeks2").checked)
        }

        function test_3_istAndPlan() {
            Store.saveSession(athlete, thisMonday, "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 60, reps: 2, sets: 2 }] } ] })
            Store.saveSession(athlete, thisMonday, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 65, reps: 2, sets: 2 }] } ] })
            page.show("chart")
            const tab = findChild(page, "chartTab")
            mouseClick(findChild(findChild(tab, "chartRanges"), "weeks2"))
            const both = findChild(tab, "chartBoth")
            mouseClick(both)
            tryVerify(() => both.checked)
            const chart = findChild(page, "analysisChart")
            tryVerify(() => chart.lines.length === 4)
            compare(chart.lines.map(l => l.name), ["MHG Ist", "BW Ist", "MHG Plan", "BW Plan"])
            compare(chart.lines.map(l => !!l.dashed), [false, false, true, true])
            compare(chart.lines[1].values[1], 60)
            compare(chart.lines[3].values[1], 65)
            compare(chart.bars.map(b => b.name), ["Wh pro TÜ Ist", "Wh pro TÜ Plan"])
            Store.removeAthlete(athlete)
        }
    }
}
