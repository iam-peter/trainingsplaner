// The screenshots in docs/screenshots, with invented data only: the demo
// athletes, a MAZ "Herbst 2026" with an ITP scaled from the RTK 2019's U17
// sample plan, earlier weeks done and two competitions to come. Run from
// the repository with the program built:
//   QT_QPA_PLATFORM=offscreen build/tst_qml -input docs/screenshots/take_screenshots.qml
// then python3 docs/screenshots/schemes.py for week-schemes.png. print.png
// is the printed week plan, saved by hand.
import QtQuick
import QtTest
import Trainingsplaner

Item {
    Component { id: mainWindow; Main {} }
    ItpModel { id: itp; weeks: 13; exercises: [1, -1] }
    TestCase {
        name: "Screenshots"
        when: windowShown
        property var w
        property string mazId
        function shot(name) {
            waitForRendering(w.contentItem)
            wait(300)
            grabImage(w.contentItem.parent).save(Qt.resolvedUrl(name).toString().replace("file://", ""))
        }
        function cleanupTestCase() {
            if (mazId) Plan.removeMaz(mazId)
            if (Store.hasDemoData) Store.removeDemoData()
            Store.colorScheme = "light"
        }
        function test_shots() {
            const plan = [{"load": "m", "mhg": 65, "bw": 70, "wh17": 336}, {"load": "h", "mhg": 67, "bw": 72, "wh17": 417}, {"load": "h", "mhg": 71, "bw": 74, "wh17": 424}, {"load": "g", "mhg": 73, "bw": 77, "wh17": 307}, {"load": "h", "mhg": 74, "bw": 80, "wh17": 411}, {"load": "h", "mhg": 76, "bw": 83, "wh17": 366}, {"load": "g", "mhg": 71, "bw": 78, "wh17": 250}, {"load": "h", "mhg": 79, "bw": 88, "wh17": 318}, {"load": "h", "mhg": 81, "bw": 90, "wh17": 289}, {"load": "g", "mhg": 73, "bw": 85, "wh17": 230}, {"load": "h", "mhg": 81, "bw": 95, "wh17": 225}, {"load": "m", "mhg": 83, "bw": 97, "wh17": 183}, {"load": "g", "mhg": 84, "bw": 100, "wh17": 156}]
            Store.colorScheme = "light"
            Store.sessionsPerDay = 1
            Store.showPreviousWeek = false
            w = createTemporaryObject(mainWindow, null, { width: 1366, height: 900, visible: true})
            const anna = Store.createDemoData()
            w.athlete = anna
            const today = Store.mondayOf(Store.today())
            mazId = Plan.saveMaz({ name: "Herbst 2026", shortName: "H26", sex: 1, from: "38/2026", to: "50/2026",
                                   buildUp: "42/2026", peakPhase: "47/2026" }).id
            Plan.saveMazAthlete({ mazId: mazId, athleteId: anna, weightClass: 64, targetSnatch: 76, targetCleanJerk: 94,
                                  compSnatch: 69, compCleanJerk: 87 })
            itp.owner = anna
            itp.fromMonday = Store.weekFromLabel("38/2026")
            const first = itp.fromMonday
            for (let r = 0; r < 13; ++r) {
                const p = plan[r]
                const mhg = Math.round(p.mhg * 0.76), bw = Math.round(p.bw * 0.76)
                itp.setData(itp.index(r, 0), String(12 + (p.load === "g" ? 0 : 4)), Qt.UserRole + 1)
                itp.setData(itp.index(r, 1), String(mhg), Qt.UserRole + 1)
                itp.setData(itp.index(r, 2), String(bw), Qt.UserRole + 1)
                itp.setData(itp.index(r, 3), String(Math.round(p.wh17 * 0.38)), Qt.UserRole + 1)
                itp.setData(itp.index(r, 6), p.load, Qt.UserRole + 1)
                const m = Store.addWeeks(first, r)
                // Earlier weeks done, before the demo's own
                if (m < Store.addWeeks(today, -3)) {
                    const off = [-2, -1, -3, -1, -2][r] || -2
                    Store.saveSession(anna, m, "I", { day: 1, number: 2, from: "15:30", entries: [
                        { kind: 0, exercise: 1, steps: [{ kg: mhg - 6 + off, reps: 3, sets: 2 }, { kg: mhg + off, reps: 2, sets: 3 },
                                                         { kg: bw + off, reps: 1, sets: 2 }] },
                        { kind: 0, exercise: 19, steps: [{ kg: 75, reps: 5, sets: 2 }, { kg: 85, reps: 3, sets: 3 }] }] })
                    Store.saveSession(anna, m, "I", { day: 3, number: 2, from: "15:30", entries: [
                        { kind: 0, exercise: 3, steps: [{ kg: 70, reps: 2, sets: 3 }, { kg: 78, reps: 1, sets: 3 }] }] })
                }
            }
            Store.saveCompetitionDate(anna, "2026-11-21", 0, "Landesmeisterschaft", "Halle", "", "")
            Store.saveCompetitionDate(anna, "2026-12-12", 1, "Deutsche Meisterschaft", "Berlin", "", "")

            keyClick(Qt.Key_2, Qt.ControlModifier)
            const week = findChild(w, "weekPage")
            week.monday = today
            shot("week.png")
            for (const s of ["dark", "classic"]) {
                Store.colorScheme = s
                shot("week-" + s + ".png")
            }
            Store.colorScheme = "light"

            week.openSession(1, 2)
            const ed = findChild(w, "sessionEditor")
            ed.addEntry({ kind: 0, exercise: 3 }, false)
            wait(400)
            const kg = findChild(findChild(ed, "entry4"), "kg0")
            kg.forceActiveFocus()
            keyClick("7"); keyClick("0")
            wait(500)
            shot("session.png")
            ed.dirty = false
            ed.close()

            week.showMonth(true)
            shot("month.png")
            week.showMonth(false)

            findChild(w, "loadChartButton").clicked()
            wait(500)
            shot("load.png")
            findChild(w, "loadChartDialog").close()
            wait(300)

            keyClick(Qt.Key_3, Qt.ControlModifier)
            const planning = findChild(w, "planningPage")
            planning.showTab("itp")
            wait(300)
            shot("planning.png")

            keyClick(Qt.Key_4, Qt.ControlModifier)
            const analysis = findChild(w, "analysisTabs")
            analysis.currentIndex = 3
            wait(500)
            shot("analysis.png")

            keyClick(Qt.Key_5, Qt.ControlModifier)
            shot("competitions.png")
        }
    }
}
