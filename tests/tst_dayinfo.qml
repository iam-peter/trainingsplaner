import QtQuick
import QtTest
import Trainingsplaner

Item {
    id: window
    width: 900
    height: 700

    DayInfoDialog { id: dialog }

    TestCase {
        name: "DayInfo"
        when: windowShown

        readonly property string athlete: "test_tina"
        readonly property string monday: "2026-11-23"

        function test_addSummariseRemove() {
            compare(Store.saveDayInfo(athlete, "2026-11-23", "", "KG", "74,5", "", "", ""), "")
            compare(Store.saveDayInfo(athlete, "2026-11-25", "07:30", "KG", "75,2", "", "", ""), "")
            compare(Store.saveDayInfo(athlete, "2026-11-25", "", "CRE", "5", "", "", ""), "")
            compare(Store.saveDayInfo(athlete, "2026-11-26", "", "CRE", "5", "", "", ""), "")
            verify(Store.saveDayInfo(athlete, "2026-11-26", "", "CRE", "viel", "", "", "") !== "")

            const entries = Store.dayInfo(athlete, monday)
            compare(entries.length, 4)
            const wed = entries.find(e => e.date === "2026-11-25" && e.code === "KG")
            compare(wed.time, "07:30")
            compare(wed.valueText, "75,2")
            // Body weight: maximum of the week, Creatin: sum
            compare(Store.weekInfoSummary(athlete, monday), "Körpergewicht 75,2 kg  ·  Creatin 10 g")

            // Edit: move the Monday weight to Tuesday
            compare(Store.saveDayInfo(athlete, "2026-11-24", "", "KG", "74,0", "2026-11-23", "", "KG"), "")
            verify(!Store.dayInfo(athlete, monday).some(e => e.date === "2026-11-23"))

            dialog.edit(athlete, monday)
            tryCompare(dialog, "opened", true)
            compare(dialog.entries.length, 4)
            dialog.close()

            for (const e of Store.dayInfo(athlete, monday))
                Store.removeDayInfo(athlete, e.code, e.date, e.time)
            compare(Store.dayInfo(athlete, monday).length, 0)
        }
    }
}
