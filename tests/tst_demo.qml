import QtQuick
import QtTest
import Trainingsplaner

// The example data shows every view: besides the weeks around today, each
// athlete has a MAZ of 13 weeks with today in its ninth, an ITP from the
// RTK's U17 sample plan with its loads, done weeks before, and two
// competitions to come. Removing the example data removes the MAZ too.
Item {
    TestCase {
        name: "Demo"

        property string anna

        function initTestCase() {
            anna = Store.createDemoData()
            verify(anna !== "")
        }

        function cleanupTestCase() {
            if (Store.hasDemoData)
                Store.removeDemoData()
        }

        function test_mazAroundToday() {
            const list = Plan.mazForAthlete(anna)
            compare(list.length, 1)
            const z = list[0]
            const monday = Store.mondayOf(Store.today())
            compare(Plan.mondayFromLabel(z.from), Store.addWeeks(monday, -8))
            compare(Plan.mondayFromLabel(z.to), Store.addWeeks(monday, 4))
            // The week plan names the MAZ and the week's load: the U17
            // plan's ninth week is "h"
            const ctx = Store.weekContext(anna, monday)
            verify(ctx.maz.has)
            compare(ctx.maz.week, 9)
            compare(ctx.loadText, "h")
        }

        // The Belastungsverlauf of the snatch: targets in every week, the
        // U17 plan's loads, done weeks up to last week, today marked
        function test_loadCourse() {
            const z = Plan.mazForAthlete(anna)[0]
            const c = Plan.loadCourse(anna, z.id, "", 0, 1, "kg")
            compare(c.labels.length, 13)
            compare(c.load.join(""), "mhhghhghhghmg")
            compare(c.todayIndex, 8)
            verify(c.target.bw.every(v => v > 0))
            verify(c.target.wh.every(v => v > 0))
            // K1-7 of the U17 plan's ninth week (289 WH), scaled: on the
            // groups, together about 110
            verify(Math.abs(c.target.wh[8] - 110) <= 2, c.target.wh[8])
            // Ist: the eight weeks before this one
            for (let i = 0; i < 13; ++i)
                compare(c.actual.bw[i] !== null && c.actual.bw[i] > 0, i < 8, "week " + i)
            // Scaled to her: target snatch 76 kg for the plan's 100, on the
            // 2.5 kg step
            compare(c.target.bw[12], 75)
        }

        // The MAZ's framework plan is the sample plan in percent; the
        // ITP is what "Vorlage" makes of it for her, so a new Vorlage
        // changes nothing
        function test_frameworkPlan() {
            const z = Plan.mazForAthlete(anna)[0]
            const ro = Plan.loadCourse(anna, z.id, "", 0, 1, "kg")
            const before = ro.target.bw.slice()
            verify(Plan.itpFromRo(z.id, anna))
            compare(Plan.loadCourse(anna, z.id, "", 0, 1, "kg").target.bw, before)
        }

        function test_competitionsToCome() {
            const today = Store.today()
            const coming = Store.competitions(anna).filter(c => c.date > today)
            compare(coming.length, 2)
            verify(coming.some(c => c.name === "Deutsche Meisterschaft"))
        }

        function test_removedWithTheData() {
            Store.removeDemoData()
            verify(!Plan.mazList.some(z => z.name.indexOf("Beispiel-MAZ") === 0))
            compare(Plan.mazForAthlete(anna).length, 0)
        }
    }
}
