// The screenshots of the README (docs/screenshots) and of the handbook
// (docs/handbuch/bilder), with the program's example data only: the two
// invented athletes, their MAZ with the ITP from the RTK 2019's U17
// sample plan, done weeks and competitions to come. Run from the
// repository with the program built:
//   QT_QPA_PLATFORM=offscreen build/tst_qml -input docs/screenshots/take_screenshots.qml
// then python3 docs/screenshots/schemes.py for week-schemes.png. print.png
// is the printed week plan, saved by hand.
import QtQuick
import QtTest
import Trainingsplaner

Item {
    Component { id: mainWindow; Main {} }
    TestCase {
        name: "Screenshots"
        when: windowShown
        property var w

        function save(path) {
            waitForRendering(w.contentItem)
            wait(300)
            grabImage(w.contentItem.parent).save(Qt.resolvedUrl(path).toString().replace("file://", ""))
        }
        // README
        function shot(name) { save(name) }
        // Handbook
        function page(name) { save("../handbuch/bilder/" + name) }

        function cleanupTestCase() {
            if (Store.hasDemoData)
                Store.removeDemoData()
            Store.colorScheme = "light"
        }

        function test_shots() {
            // Only the example athletes: the test database's own goes
            Store.removeAthlete("test_tina")
            Store.colorScheme = "light"
            Store.sessionsPerDay = 2
            Store.showPreviousWeek = false
            Store.trainer = "Max Mustermann"
            w = createTemporaryObject(mainWindow, null, { width: 1366, height: 860, visible: true })

            // The welcome dialog of the first start, then its example data
            const welcome = findChild(w, "welcomeDialog")
            welcome.open()
            tryCompare(welcome, "opened", true)
            page("01-willkommen.png")
            welcome.close()
            tryCompare(welcome, "visible", false)
            const anna = Store.createDemoData()
            w.athlete = anna
            const today = Store.mondayOf(Store.today())
            const maz = Plan.mazForAthlete(anna)[0].id

            // The dumbbell menu
            const menu = findChild(w, "fileMenu")
            menu.open()
            tryCompare(menu, "opened", true)
            page("02-menue.png")
            menu.close()
            tryCompare(menu, "visible", false)

            // Week plan
            keyClick(Qt.Key_2, Qt.ControlModifier)
            const week = findChild(w, "weekPage")
            week.monday = today
            shot("week.png")
            page("04-wochenplan.png")
            for (const s of ["dark", "classic"]) {
                Store.colorScheme = s
                shot("week-" + s + ".png")
            }
            Store.colorScheme = "light"

            // A session in the panel, a weight typed
            week.openSession(1, 2)
            const ed = findChild(w, "sessionEditor")
            ed.addEntry({ kind: 0, exercise: 3 }, false)
            wait(400)
            const kg = findChild(findChild(ed, "entry4"), "kg0")
            kg.forceActiveFocus()
            keyClick("6"); keyClick("5")
            wait(500)
            shot("session.png")
            page("05-trainingseinheit.png")
            ed.dirty = false
            ed.close()
            wait(300)

            // One exercise over the week (Erfassung TÜ)
            week.openExercise(1)
            wait(500)
            page("06-erfassung-tue.png")
            week.closePanel()
            wait(300)

            // The week before above the week
            Store.showPreviousWeek = true
            wait(300)
            page("07-vorwoche.png")
            Store.showPreviousWeek = false

            // Zusatzinfo
            const info = findChild(w, "dayInfoDialog")
            info.edit(anna, today)
            tryCompare(info, "opened", true)
            page("08-zusatzinfo.png")
            info.close()
            tryCompare(info, "visible", false)

            // Month, and a competition entered on a day of it
            week.showMonth(true)
            shot("month.png")
            page("09-monat.png")
            const comp = findChild(w, "competitionDialog")
            comp.show(null, Store.addWeeks(today, 2).replace(/-(\d\d)$/, (m, d) => "-" + String(Number(d) + 5).padStart(2, "0")), anna)
            tryCompare(comp, "opened", true)
            // A name typed: the list of the DGJ's competitions closes
            const name = findChild(comp.contentItem, "nameField")
            name.text = "Vereinspokal"
            keyClick(Qt.Key_Tab)
            page("10-wettkampf-eintragen.png")
            comp.close()
            tryCompare(comp, "visible", false)
            week.showMonth(false)

            // Belastungsverlauf
            findChild(w, "loadChartButton").clicked()
            wait(600)
            shot("load.png")
            page("11-belastungsverlauf.png")
            findChild(w, "loadChartDialog").close()
            wait(300)

            // Athletes
            keyClick(Qt.Key_1, Qt.ControlModifier)
            page("03-sportler.png")

            // Planning: MAZ, Rahmenorientierung, ITP, Laststufen
            keyClick(Qt.Key_3, Qt.ControlModifier)
            const planning = findChild(w, "planningPage")
            planning.showTab("maz")
            findChild(planning, "mazPane").select(maz)
            page("12-planung-maz.png")
            planning.openFramework(maz)
            wait(400)
            page("13-planung-rahmenorientierung.png")
            planning.closeFramework()
            planning.showTab("itp")
            planning.chooseMaz(maz)
            wait(400)
            shot("planning.png")
            page("14-planung-itp.png")
            planning.showTab("laststufen")
            wait(400)
            page("15-planung-laststufen.png")

            // Analysis
            keyClick(Qt.Key_4, Qt.ControlModifier)
            const analysis = findChild(w, "analysisPage")
            for (const [name, file] of [["individual", "16-analyse-individual.png"], ["group", "17-analyse-gruppe.png"],
                                        ["check", "18-analyse-datenpruefung.png"], ["chart", "19-analyse-grafik.png"]]) {
                analysis.show(name)
                wait(600)
                page(file)
            }
            shot("analysis.png")

            // Competitions: results and chart
            keyClick(Qt.Key_5, Qt.ControlModifier)
            const competitions = findChild(w, "competitionsPage")
            competitions.edit(Store.competitions(anna).find(c => c.total > 0))
            shot("competitions.png")
            page("20-wettkaempfe.png")
            competitions.showChart()
            wait(500)
            page("21-wettkaempfe-grafik.png")

            // Settings
            keyClick(Qt.Key_2, Qt.ControlModifier)
            const settings = findChild(w, "settingsDialog")
            settings.open()
            tryCompare(settings, "opened", true)
            page("22-einstellungen.png")
            settings.close()
        }
    }
}
