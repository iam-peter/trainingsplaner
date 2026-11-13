import QtQuick
import QtTest
import Trainingsplaner

// The month view: weeks with load and reps, sessions in four states,
// competitions entered as dates, and the way back to a week
Item {
    id: window
    width: 1400
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "Month"
        when: windowShown

        readonly property string athlete: "test_mona"
        // A past month (sessions can be "offen") and a future one ("geplant")
        readonly property string past: "2020-03-02"      // Monday, KW 10/2020
        readonly property string future: "2031-03-03"    // Monday, KW 10/2031
        property string mazId

        function session(m, v, day, kg) {
            Store.saveSession(athlete, m, v, { day: day, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: kg, reps: 3, sets: 2 }] }] })
        }

        function initTestCase() {
            session(past, "P", 1, 50); session(past, "I", 1, 50)    // done
            session(past, "I", 2, 55)                                // without a plan
            session(past, "P", 3, 60)                                // open
            session(future, "P", 1, 60)                              // planned
            Store.saveCompetition({ athleteId: athlete, date: "2020-03-07", name: "LM Jugend", place: "Halle",
                                    bodyWeight: "60", snatch: [50, 52, -54], cleanJerk: [60, 0, 0] }, "", "")
            Store.saveCompetitionDate(athlete, "2031-03-08", 1, "DM Jugend", "Berlin", "", "")
            mazId = Plan.saveMaz({ name: "Monats-MAZ", shortName: "MM", sex: 1, from: "10/2031", to: "14/2031",
                                   buildUp: "12/2031", peakPhase: "14/2031" }).id
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete })
        }

        function cleanupTestCase() {
            for (const [m, v, d] of [[past, "P", 1], [past, "I", 1], [past, "I", 2], [past, "P", 3], [future, "P", 1]])
                Store.removeSession(athlete, m, v, d, 1)
            Store.removeCompetition(athlete, "2020-03-07", "")
            Store.removeCompetition(athlete, "2031-03-09", "")
            Store.removeCompetition(athlete, "2031-03-08", "")
            Plan.removeMaz(mazId)
            page.showMonth(false)
        }

        function dayOf(m, date) {
            for (const w of m.weeks)
                for (const d of w.days)
                    if (d.date === date)
                        return d
            return null
        }

        function test_monthData() {
            const m = Store.month(athlete, "2020-03-15", false)
            compare(m.title, "März 2020")
            compare(m.weeks[0].monday, "2020-02-24")      // the week of the 1st
            compare(m.weeks.length, 6)
            compare(dayOf(m, "2020-03-02").sessions[0].state, "done")
            compare(dayOf(m, "2020-03-02").sessions[0].wh, 6)
            compare(dayOf(m, "2020-03-03").sessions[0].state, "free")
            compare(dayOf(m, "2020-03-04").sessions[0].state, "open")
            compare(dayOf(m, "2020-02-24").inMonth, false)
            const w10 = m.weeks[1]
            compare(w10.whPlan, 12)
            compare(w10.whActual, 12)
            const c = dayOf(m, "2020-03-07").competitions[0]
            compare(c.name, "LM Jugend")
            verify(c.hasResult)
            // The report for printing: a header and a row per week
            compare(m.report.blocks[0].rows.length, 7)

            const f = Store.month(athlete, "2031-03-01", false)
            compare(dayOf(f, "2031-03-03").sessions[0].state, "planned")
            compare(f.weeks[1].phase, "Grundlagenphase")
            compare(f.weeks[3].phase, "Aufbauphase")
            compare(f.upcoming[0].name, "DM Jugend")
        }

        // Changing a competition's date from the month keeps its results
        function test_dateKeepsResults() {
            compare(Store.saveCompetitionDate(athlete, "2020-03-08", 1, "LM Jugend", "Halle", "2020-03-07", ""), "")
            const c = Store.competitions(athlete).find(x => x.date === "2020-03-08")
            compare(c.bestSnatch, 52)
            compare(c.type, 1)
            compare(Store.saveCompetitionDate(athlete, "07.03.2020", 0, "LM Jugend", "Halle", "2020-03-08", ""), "")
            verify(Store.competitions(athlete).find(x => x.date === "2020-03-07").bestSnatch === 52)
            verify(Store.saveCompetitionDate("", "2020-03-08", 0, "x", "", "", "") !== "")
        }

        // A new competition on a day that has one (no time either) would
        // replace it, results and all: refused
        function test_noOverwrite() {
            verify(Store.saveCompetitionDate(athlete, "2020-03-07", 0, "Pokal", "", "", "").indexOf("schon") > 0)
            compare(Store.competitions(athlete).find(x => x.date === "2020-03-07").bestSnatch, 52)
            // Nor by moving another one there
            compare(Store.saveCompetitionDate(athlete, "2020-03-14", 0, "Pokal", "", "", ""), "")
            verify(Store.saveCompetitionDate(athlete, "2020-03-07", 0, "Pokal", "", "2020-03-14", "") !== "")
            compare(Store.competitions(athlete).find(x => x.date === "2020-03-07").bestSnatch, 52)
            verify(Store.competitions(athlete).some(x => x.date === "2020-03-14"))
            Store.removeCompetition(athlete, "2020-03-14", "")
        }

        function test_monthView() {
            page.athleteId = athlete
            page.monday = future
            page.showMonth(true)
            const view = findChild(page, "monthView")
            tryCompare(view, "visible", true)
            compare(page.monthDay, "2031-03-06")
            compare(findChild(page, "monthTitle").text, "März 2031")
            // Ctrl+→ is the next month here
            keyClick(Qt.Key_Right, Qt.ControlModifier)
            compare(findChild(page, "monthTitle").text, "April 2031")
            keyClick(Qt.Key_Left, Qt.ControlModifier)

            // A double click on a day enters a competition there
            const day = findChild(view, "monthDay2031-03-12")
            tryVerify(() => day !== null)
            waitForRendering(page)
            mouseDoubleClickSequence(day, day.width / 2, day.height - 8)
            const dialog = findChild(page, "competitionDialog")
            tryCompare(dialog, "opened", true)
            compare(findChild(dialog.contentItem, "dateField").text, "12.03.2031")
            findChild(dialog.contentItem, "nameField").text = "Kreismeisterschaft"
            dialog.save()
            tryCompare(dialog, "visible", false)
            tryVerify(() => findChild(view, "monthDay2031-03-12").children.length > 0
                            && view.monthData.weeks[2].days[2].competitions.length === 1)
            Store.removeCompetition(athlete, "2031-03-12", "")

            // A click on a week number opens that week
            waitForRendering(page)
            const weekCell = findChild(findChild(view, "monthWeek2"), "weekCell")
            mouseClick(weekCell)
            compare(page.monthMode, false)
            compare(page.monday, "2031-03-10")
        }
    }
}
