import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// The development curve after Sandau (2018) in the competition chart: a
// Gompertz fit of the yearly best total and body weight, two years ahead
// with a band, and the weight classes around the body weight
Item {
    width: 1300
    height: 800

    CompetitionsPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "DevelopmentCurve"
        when: windowShown

        property string athlete
        readonly property var totals: [95, 128, 150, 158, 178, 184]
        readonly property var weights: [48, 53.5, 56, 58.5, 60, 61]

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Kurve", firstName: "Karla", sex: 1, born: "01.03.2004" })
            for (let i = 0; i < totals.length; ++i) {
                const s = Math.round(totals[i] * 0.44), j = totals[i] - s
                Store.saveCompetition({ athleteId: athlete, date: (2016 + i) + "-05-10", name: "LM", type: 0,
                                        bodyWeight: String(weights[i]).replace(".", ","), snatch: [s, 0, 0], cleanJerk: [j, 0, 0] }, "", "")
            }
            // A second one in 2021, worse: the year's best counts
            Store.saveCompetition({ athleteId: athlete, date: "2021-10-02", name: "Pokal", type: 0,
                                    bodyWeight: "62,5", snatch: [70, 0, 0], cleanJerk: [90, 0, 0] }, "", "")
        }

        function cleanupTestCase() {
            Store.removeAthlete(athlete)
        }

        function test_trend() {
            const t = Store.competitionTrend(athlete, 2016, 2021, 2, [0], true)
            compare(t.labels, ["2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023"])
            compare(t.total.slice(0, 6), totals)
            compare(t.total[6], undefined)
            // The body weight at the year's best total
            compare(t.bodyWeight[5], 61)
            compare(t.curve.length, 8)
            verify(Math.abs(t.curve[5] - 184) < 8)
            verify(t.curve[7] > t.curve[6] && t.curve[6] > 184 && t.curve[7] < 210)
            verify(t.curveLower[6] < t.curve[6] && t.curveUpper[6] > t.curve[6])
            verify(t.curveText.indexOf("Entwicklungskurve nach Sandau (2018) aus 6 Jahren") === 0)
            verify(t.curveText.indexOf("Prognose 2022: ") > 0)
            verify(t.bodyText.indexOf("aus 6 Jahren") > 0)
            // AK 19 in 2023: the women's classes 49 to 86, those around 48-62
            compare(t.classLimits, [49, 53, 57, 61, 69])

            // Without the curve, or not yearly: as before
            compare(Store.competitionTrend(athlete, 2016, 2021, 2, [0], false).curve, undefined)
            compare(Store.competitionTrend(athlete, 2016, 2021, 0, [0], true).curve, undefined)
            // Too few years: no curve, no years ahead, and why
            const few = Store.competitionTrend(athlete, 2019, 2021, 2, [0], true)
            compare(few.labels, ["2019", "2020", "2021"])
            compare(few.curve, [])
            compare(few.curveText, "Für die Entwicklungskurve braucht es Werte aus mindestens vier Jahren, hier sind es 3.")
        }

        function test_chart() {
            page.athleteId = athlete
            page.showChart()
            findChild(page, "fromYear").value = 2016
            findChild(page, "toYear").value = 2021
            const curve = findChild(page, "showCurve")
            verify(!curve.enabled)
            findChild(page, "periodBox").currentIndex = 2
            verify(curve.enabled)
            curve.checked = true
            page.reloadTrend()
            const chart = findChild(page, "curveText")
            tryVerify(() => chart.visible && chart.text.indexOf("Entwicklungskurve") === 0)
            // Body weight: its curve and the classes as lines
            const what = findChild(page, "whatBox")
            what.currentIndex = 1
            tryVerify(() => chart.text.indexOf("aus 6 Jahren") > 0)
        }
    }
}
