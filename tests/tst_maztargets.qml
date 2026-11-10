import QtQuick
import QtTest
import Trainingsplaner

// The athletes' targets in a MAZ: leaving a field saves only a change, and
// the hidden ITP grid catches up when it shows again instead of on every
// save (which made tabbing through the targets wait for it)
Item {
    Component { id: main; Main {} }

    SignalSpy { id: planChanged; target: Plan; signalName: "changed" }

    TestCase {
        name: "MazTargets"
        when: windowShown

        function fieldWithText(item, text) {
            if (!item)
                return null
            if (item.text === text && item.validator !== undefined && item.visible)
                return item
            for (const c of item.children) {
                const r = fieldWithText(c, text)
                if (r)
                    return r
            }
            return null
        }

        function test_tabSavesOnlyChanges() {
            const w = createTemporaryObject(main, null)
            const id = Store.createDemoData()
            const today = Store.mondayOf(Store.today())
            const maz = Plan.saveMaz({ name: "Probe", shortName: "PR", sex: 1, from: Store.weekLabel(today),
                                       to: Store.weekLabel(Store.addWeeks(today, 15)), buildUp: Store.weekLabel(today),
                                       peakPhase: Store.weekLabel(Store.addWeeks(today, 10)) }).id
            Plan.saveMazAthlete({ mazId: maz, athleteId: id, weightClass: 64, targetSnatch: 75, targetCleanJerk: 98 })
            w.athlete = id
            findChild(w, "mainTabs").currentIndex = w.planningTab
            const plan = findChild(w, "planningPage")
            plan.showTab("itp")
            plan.chooseMaz(maz)
            plan.showTab("maz")
            findChild(plan, "mazPane").select(maz)
            let field = null
            tryVerify(() => (field = fieldWithText(plan, "64")) !== null)

            // Tabbing through: nothing changed, nothing saved
            planChanged.clear()
            field.forceActiveFocus()
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Tab)
            compare(planChanged.count, 0)

            // A change is saved once; the hidden grid only notes it
            field.forceActiveFocus()
            field.text = "67"
            keyClick(Qt.Key_Tab)
            compare(planChanged.count, 1)
            compare(Plan.mazAthletes(maz).find(a => a.athleteId === id).weightClass, 67)
            keyClick(Qt.Key_Tab)
            compare(planChanged.count, 1)
            verify(plan.itpStale)
            plan.showTab("itp")
            tryVerify(() => !plan.itpStale)

            Plan.removeMaz(maz)
            Store.removeDemoData()
        }
    }
}
