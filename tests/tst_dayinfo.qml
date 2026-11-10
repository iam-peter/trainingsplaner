import QtQuick
import QtTest
import QtQuick.Controls
import Trainingsplaner

// Zusatzinfo: the week's entries as rows of fields, saved together; a
// wrong row stops the save, Abbrechen keeps the week as it was
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

        function rowsOf(item, out) {
            for (const c of item.children) {
                if (c.objectName === "infoRow" && c.index >= 0)
                    out.push(c)
                rowsOf(c, out)
            }
            return out.sort((a, b) => a.index - b.index)
        }

        function setText(field, text) {
            field.text = text
            field.textEdited()
        }

        function cleanup() {
            compare(Store.saveWeekInfo(athlete, monday, []), "")
        }

        function test_saveSummarise() {
            compare(Store.saveWeekInfo(athlete, monday, [
                { date: "2026-11-23", time: "", code: "KG", value: "74,5" },
                { date: "2026-11-25", time: "07:30", code: "KG", value: "75,2" },
                { date: "2026-11-25", time: "", code: "CRE", value: "5" },
                { date: "2026-11-26", time: "", code: "CRE", value: "5" },
                // No value: left out
                { date: "2026-11-27", time: "", code: "CRE", value: "" },
            ]), "")
            const entries = Store.dayInfo(athlete, monday)
            compare(entries.length, 4)
            const wed = entries.find(e => e.date === "2026-11-25" && e.code === "KG")
            compare(wed.time, "07:30")
            compare(wed.valueText, "75,2")
            // Body weight: maximum of the week, Creatin: sum
            compare(Store.weekInfoSummary(athlete, monday), "Körpergewicht 75,2 kg  ·  Creatin 10 g")

            // A wrong row names itself and saves nothing
            const wrong = Store.saveWeekInfo(athlete, monday, [
                { date: "2026-11-24", time: "", code: "KG", value: "74" },
                { date: "2026-11-24", time: "", code: "CRE", value: "viel" },
            ])
            verify(wrong.startsWith("Zeile 2:"), wrong)
            compare(Store.dayInfo(athlete, monday).length, 4)
            verify(Store.saveWeekInfo(athlete, monday, [
                { date: "2026-11-24", time: "", code: "KG", value: "74" },
                { date: "2026-11-24", time: "", code: "KG", value: "75" },
            ]).startsWith("Zeile 2:"))
            verify(Store.saveWeekInfo(athlete, monday, [
                { date: "2026-12-01", time: "", code: "KG", value: "74" },
            ]).startsWith("Zeile 1:"))
        }

        function test_editInDialog() {
            compare(Store.saveWeekInfo(athlete, monday, [
                { date: "2026-11-23", time: "", code: "KG", value: "74,5" },
            ]), "")
            dialog.edit(athlete, monday)
            tryCompare(dialog, "opened", true)
            tryVerify(() => rowsOf(dialog.contentItem, []).length === 1)
            let rows = rowsOf(dialog.contentItem, [])
            compare(findChild(rows[0], "valueField").text, "74,5")
            compare(findChild(rows[0], "valueField").unit, "kg")
            verify(!dialog.dirty)

            // Change the value, add a Creatin row on Wednesday, save
            setText(findChild(rows[0], "valueField"), "74,0")
            mouseClick(findChild(dialog.footer, "addButton"))
            tryVerify(() => rowsOf(dialog.contentItem, []).length === 2)
            const added = rowsOf(dialog.contentItem, [])[1]
            const day = findChild(added, "dayBox")
            day.currentIndex = 2
            day.activated(2)
            const cat = findChild(added, "categoryBox")
            const cre = Store.infoCategories.findIndex(c => c.code === "CRE")
            cat.currentIndex = cre
            cat.activated(cre)
            setText(findChild(added, "valueField"), "5")
            mouseClick(findChild(dialog.footer, "saveButton"))
            tryCompare(dialog, "visible", false)
            const entries = Store.dayInfo(athlete, monday)
            compare(entries.map(e => e.date + " " + e.code + " " + e.valueText).join(", "),
                    "2026-11-23 KG 74,0, 2026-11-25 CRE 5")

            // Removed and cancelled: the week stays as it was
            dialog.edit(athlete, monday)
            tryCompare(dialog, "opened", true)
            tryVerify(() => rowsOf(dialog.contentItem, []).length === 2)
            rows = rowsOf(dialog.contentItem, [])
            mouseClick(findChild(rows[0], "removeButton"))
            verify(dialog.dirty)
            mouseClick(findChild(dialog.footer, "cancelButton"))
            const confirm = findChild(dialog, "discardConfirm")
            tryCompare(confirm, "opened", true)
            mouseClick(confirm.standardButton(Dialog.Discard))
            tryCompare(dialog, "visible", false)
            compare(Store.dayInfo(athlete, monday).length, 2)
        }

        // An empty week starts with one row to type in, which is not a change
        function test_emptyWeekHasARow() {
            dialog.edit(athlete, monday)
            tryCompare(dialog, "opened", true)
            tryVerify(() => rowsOf(dialog.contentItem, []).length === 1)
            verify(!dialog.dirty)
            dialog.close()
            tryCompare(dialog, "visible", false)
        }
    }
}
