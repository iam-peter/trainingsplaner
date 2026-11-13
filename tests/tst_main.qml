import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// The pages share one athlete: choosing one on any page shows them on all.
// A dialog blocks the window behind it.
Item {
    Component {
        id: mainComponent
        Main {}
    }

    TestCase {
        name: "SharedAthlete"
        when: windowShown

        property string second

        function initTestCase() {
            second = Store.saveAthlete({ lastName: "Zweite", firstName: "Zoe", sex: 1 })
        }

        function cleanupTestCase() {
            Store.removeAthlete(second)
        }

        // Shows every tab once, so all pages are built, and goes back to
        // the week plan
        function openAllPages(w) {
            const tabs = findChild(w, "mainTabs")
            for (let i = 0; i < 5; ++i)
                tabs.currentIndex = i
            tabs.currentIndex = w.weekTab
        }

        // Only the week plan is built at start; another page when its tab
        // is first shown, then with the athlete all pages show. It stays
        // when the tab is left.
        function test_pagesBuiltWhenShown() {
            const w = createTemporaryObject(mainComponent, null)
            verify(findChild(w, "weekPage") !== null)
            for (const name of ["athletesPage", "planningPage", "analysisPage", "competitionsPage"])
                compare(findChild(w, name), null, name)
            w.athlete = second
            const tabs = findChild(w, "mainTabs")
            tabs.currentIndex = w.planningTab
            const planning = findChild(w, "planningPage")
            verify(planning !== null)
            compare(w.planningPage, planning)
            compare(planning.athleteId, second)
            tabs.currentIndex = w.athletesTab
            compare(findChild(w, "athletesPage").selectedId, second)
            tabs.currentIndex = w.weekTab
            compare(findChild(w, "planningPage"), planning)
            compare(findChild(w, "analysisPage"), null)
            // Ctrl+4 builds the analysis
            keyClick(Qt.Key_4, Qt.ControlModifier)
            tryVerify(() => findChild(w, "analysisPage") !== null)
            compare(findChild(w, "analysisPage").athleteId, second)
        }

        // The window chooses the first athlete for all pages, also when
        // athletes come later (example data), without the pages fighting
        // over it (they each chose one, a binding loop)
        function test_defaultAthleteChosenOnce() {
            failOnWarning(/Binding loop/)
            const w = createTemporaryObject(mainComponent, null)
            openAllPages(w)
            verify(w.athlete !== "")
            const demo = Store.createDemoData()
            w.athlete = ""
            Store.saveAthlete({ lastName: "Dritte", firstName: "Dora", sex: 1 })   // athletes change
            verify(w.athlete !== "")
            for (const name of ["weekPage", "planningPage", "analysisPage", "competitionsPage"])
                compare(findChild(w, name).athleteId, w.athlete, name)
            Store.removeDemoData()
            const dora = Store.athletes.find(a => a.lastName === "Dritte")
            if (dora)
                Store.removeAthlete(dora.id)
        }

        // One menu at the window's left, before the tabs, holds projects,
        // import and export, the settings and help; it opens under its button
        function test_fileMenu() {
            const w = createTemporaryObject(mainComponent, null)
            waitForRendering(w.contentItem)
            const b = findChild(w, "fileButton"), m = findChild(w, "fileMenu")
            const tabs = findChild(w, "mainTabs")
            verify(b.mapToItem(null, b.width, 0).x <= tabs.mapToItem(null, 0, 0).x)
            compare(b.icon.source.toString().indexOf("dumbbell") >= 0, true)
            // Only the icon, without a tooltip
            compare(b.display, AbstractButton.IconOnly)
            compare(b.toolTip, "")
            for (const name of ["dataButton", "settingsButton", "helpButton"])
                compare(findChild(w, name), null, name)
            m.open()
            tryCompare(m, "opened", true)
            const left = b.mapToItem(null, 0, 0).x
            verify(Math.abs(m.background.mapToItem(null, 0, 0).x - left) <= 1)
            const texts = []
            for (let i = 0; i < m.count; ++i)
                texts.push(m.itemAt(i).text ?? "")
            for (const t of ["Neues Projekt…", "Öffnen…", "Zuletzt geöffnet", "Speichern unter…", "Importieren…",
                             "Exportieren…", "Einstellungen…", "Hilfe", "Über den Trainingsplaner", "Beenden"])
                verify(texts.indexOf(t) >= 0, t + " in " + texts)
            m.close()
            tryCompare(m, "visible", false)
            // At the smallest width the tabs still fit beside it
            w.width = w.minimumWidth
            waitForRendering(w.contentItem)
            verify(tabs.mapToItem(null, tabs.width, 0).x <= w.width)
        }

        // No icon image without an icon: one asks the desktop's icon theme
        // for a nameless icon, which on Linux searches every folder of every
        // theme. With a field's or check box's unused icon that made the
        // start take seconds.
        function test_noEmptyIconImages() {
            const w = createTemporaryObject(mainComponent, null)
            waitForRendering(w.contentItem)
            let count = 0
            const empty = []
            const walk = (item) => {
                if (String(item).indexOf("QQuickIconImage") === 0) {
                    ++count
                    if (String(item.source) === "" && item.name === "")
                        empty.push(String(item.parent))
                }
                for (const child of item.children)
                    walk(child)
            }
            walk(w.contentItem)
            verify(count > 10)
            compare(empty.length, 0, empty.slice(0, 5).join(", "))
        }

        function test_choosingOnOnePageSelectsEverywhere() {
            const w = createTemporaryObject(mainComponent, null)
            openAllPages(w)
            const pages = ["weekPage", "planningPage", "analysisPage", "competitionsPage"]
                .map(n => findChild(w, n))
            const athletes = findChild(w, "athletesPage")

            pages[2].athleteId = second   // analysis
            for (const p of pages)
                compare(p.athleteId, second, p.objectName)

            pages[0].athleteId = "test_tina"   // week plan
            for (const p of pages)
                compare(p.athleteId, "test_tina", p.objectName)

            athletes.select(second)   // athletes page
            for (const p of pages)
                compare(p.athleteId, second, p.objectName)

            // Unsaved edits on the athletes page are not replaced
            athletes.dirty = true
            pages[3].athleteId = "test_tina"
            athletes.visible = false
            athletes.visible = true
            compare(athletes.selectedId, second)
        }

        // A click on the dimmed window neither closes the dialog (losing
        // what was entered) nor reaches the page: no second dialog opens
        function test_dialogBlocksTheWindow() {
            const w = createTemporaryObject(mainComponent, null)
            w.athlete = "test_tina"
            const week = findChild(w, "weekPage")
            tryVerify(() => findChild(week, "cell1_1") !== null)
            const settings = findChild(w, "settingsDialog")
            tryVerify(() => settings.Overlay.overlay && settings.Overlay.overlay.width > 0)
            settings.open()
            tryCompare(settings, "opened", true)
            mouseClick(findChild(week, "cell1_1"), 10, 10)
            wait(300)
            verify(settings.visible)
            compare(DialogStack.open, 1)
            settings.reject()
            tryCompare(DialogStack, "open", 0)
        }
    }
}
