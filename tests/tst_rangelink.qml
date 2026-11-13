import QtQuick
import QtTest
import Trainingsplaner

// "von" and "bis" stay in order: the field not edited follows and keeps
// the span the two had; empty fields are left alone
Item {
    width: 800
    height: 300

    Row {
        x: 20
        y: 20
        spacing: 8
        TimeField { id: fromTime }
        TimeField { id: toTime }
        WeekField { id: fromWeek }
        WeekField { id: toWeek }
        DateField { id: fromDate }
        DateField { id: toDate }
    }
    RangeLink { id: times; from: fromTime; to: toTime }
    RangeLink { from: fromWeek; to: toWeek; kind: "week" }
    RangeLink { from: fromDate; to: toDate; kind: "date" }

    TestCase {
        name: "RangeLink"
        when: windowShown

        // Typed like the coach does: into the field, then Enter
        function enter(field, text) {
            field.forceActiveFocus()
            field.selectAll()
            for (const c of text)
                keyClick(c)
            keyClick(Qt.Key_Return)
        }

        function test_timeEndFollowsStart() {
            fromTime.text = "15:30"
            toTime.text = "17:00"
            enter(fromTime, "1800")
            compare(fromTime.text, "18:00")
            compare(toTime.text, "19:30")
        }

        function test_timeStartFollowsEnd() {
            fromTime.text = "15:30"
            toTime.text = "17:00"
            enter(toTime, "14:00")
            compare(fromTime.text, "12:30")
            compare(toTime.text, "14:00")
        }

        function test_timeInOrderUntouched() {
            fromTime.text = "15:30"
            toTime.text = "17:00"
            enter(fromTime, "16:00")
            compare(toTime.text, "17:00")
        }

        function test_timeStaysInTheDay() {
            fromTime.text = "20:00"
            toTime.text = "23:00"
            enter(fromTime, "23:30")
            compare(toTime.text, "23:59")
        }

        function test_emptyLeftAlone() {
            fromTime.text = "15:30"
            toTime.text = ""
            enter(fromTime, "18:00")
            compare(toTime.text, "")
        }

        function test_weekEndFollowsStart() {
            fromWeek.text = "10/2027"
            toWeek.text = "13/2027"
            enter(fromWeek, "52/2027")
            compare(toWeek.text, Store.weekLabel(Store.addWeeks(fromWeek.monday, 3)))
        }

        function test_dateStartFollowsEnd() {
            fromDate.text = "01.03.2027"
            toDate.text = "10.03.2027"
            enter(toDate, "01.02.2027")
            compare(fromDate.text, Store.formatDate("2027-01-23"))
        }

        function test_mazPhasesInsideTheCycle() {
            const base = { name: "Phasen", shortName: "PH", sex: 1, from: "10/2031", to: "20/2031" }
            verify(Plan.saveMaz(Object.assign({ buildUp: "8/2031" }, base)).error !== "")
            verify(Plan.saveMaz(Object.assign({ peakPhase: "22/2031" }, base)).error !== "")
            verify(Plan.saveMaz(Object.assign({ buildUp: "15/2031", peakPhase: "12/2031" }, base)).error !== "")
            const ok = Plan.saveMaz(Object.assign({ buildUp: "12/2031", peakPhase: "16/2031" }, base))
            compare(ok.error, "")
            Plan.removeMaz(ok.id)
        }
    }
}
