import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// The analyses show their report as soon as they are opened and follow
// their settings and the data, without a button to press
Item {
    width: 1300
    height: 800

    AnalysisPage {
        id: page
        anchors.fill: parent
        athleteId: "test_tina"
    }

    TestCase {
        name: "AnalysisLive"
        when: windowShown

        function control(item, text) {
            if (!item)
                return null
            if (item.text === text && item.checked !== undefined)
                return item
            for (const c of item.children) {
                const r = control(c, text)
                if (r)
                    return r
            }
            return null
        }

        function test_showsAndFollows() {
            const monday = Store.mondayOf(Store.today())
            Store.saveSession("test_tina", monday, "I", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 61, reps: 3, sets: 1 }] } ] })
            page.show("individual")
            const report = findChild(page, "individualReport")
            tryVerify(() => report.html.indexOf("1 Reißen WKÜ") >= 0)
            // A setting rebuilds it
            const summary = control(page, "Zusammenfassung (ohne Wochenwerte)")
            const before = report.html
            summary.click()
            tryVerify(() => report.html !== before)
            summary.click()
            tryCompare(report, "html", before)
            // So does a change of the data
            Store.saveSession("test_tina", monday, "I", { day: 2, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 66, reps: 2, sets: 1 }] } ] })
            tryVerify(() => report.html !== before)
            Store.removeSession("test_tina", monday, "I", 2, 1)
            tryCompare(report, "html", before)
            Store.removeSession("test_tina", monday, "I", 1, 1)
        }

        // A hidden tab builds nothing; shown, it has its report at once
        function test_hiddenTabsWait() {
            const check = findChild(page, "checkReport")
            page.show("individual")
            verify(!check.visible)
            // Not built while the page was set up
            compare(check.html, "")
            const html = check.html
            Store.saveSession("test_tina", Store.mondayOf(Store.today()), "I", { day: 2, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 2, sets: 1 }] } ] })
            wait(200)
            verify(check.stale)
            page.show("check")
            tryVerify(() => !check.stale)
            verify(check.html.length > 0)
            Store.removeSession("test_tina", Store.mondayOf(Store.today()), "I", 2, 1)
        }
    }
}
