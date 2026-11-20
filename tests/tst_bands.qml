import QtQuick
import QtTest
import Trainingsplaner

// The RTK's intensity bands (Aufbautraining): Schnellkraft by pulls at
// 55-100 %, Maximalkraft by strength exercises at 65-110 % of the
// competition target; shown, never enforced
Item {
    width: 1400
    height: 860

    AnalysisPage {
        id: page
        anchors.fill: parent
    }
    ItpModel { id: grid }

    TestCase {
        name: "Bands"
        when: windowShown

        function test_bands() {
            const pull = Plan.intensityBand(13)
            compare([pull.has, pull.name, pull.low, pull.high], [true, "Schnellkraft", 55, 100])
            compare(pull.text, "Schnellkraft: 55–100 % des Wettkampfziels (RTK, Aufbautraining)")
            const squat = Plan.intensityBand(20)
            compare([squat.name, squat.low, squat.high], ["Maximalkraft", 65, 110])
            compare(Plan.intensityBand(15).name, "Maximalkraft")
            // The competition lifts serve both, the presses neither clearly: none
            for (const e of [1, 3, 6, 23, 25, 26, 27, 31])
                compare(Plan.intensityBand(e).has, false, "TÜ " + e)
        }

        function test_gridTips() {
            grid.exercises = [20, 1]
            compare(grid.columnInfo(2).tip, "Kniebeuge hinten\nIntensität nach RTK (Aufbautraining): Maximalkraft 65–110 % des Wettkampfziels")
            compare(grid.columnInfo(0).tip, "Kniebeuge hinten")
            compare(grid.columnInfo(5).tip, "Reißen WKÜ")
        }

        function test_charts() {
            const r = Plan.saveMaz({ name: "Band", sex: 0, from: "10/2039", to: "22/2039", template: "U17" })
            const a = Store.saveAthlete({ lastName: "Band", firstName: "Bea", sex: 1 })
            Plan.saveMazAthlete({ mazId: r.id, athleteId: a, targetSnatch: 80, targetCleanJerk: 100 })
            verify(Plan.itpFromRo(r.id, a))
            // The Belastungsverlauf: a band in % of the target, none in kg
            const dialog = findChild(page, "loadChartDialog")
            dialog.show(a, Plan.maz(r.id).fromMonday, r.id, 20)
            const chart = findChild(dialog, "loadChart")
            dialog.reference = "kg"
            tryVerify(() => dialog.course.unit === "kg")
            verify(!chart.band.has)
            dialog.reference = "ziel"
            tryVerify(() => dialog.course.unit === "%")
            compare([chart.band.low, chart.band.high], [65, 110])
            dialog.reference = "wk"
            verify(!(chart.band && chart.band.has))
            dialog.close()
            Plan.removeMaz(r.id)
            Store.removeAthlete(a)
        }
    }
}
