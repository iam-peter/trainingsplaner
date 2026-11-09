import QtQuick
import QtTest
import QtQuick.Controls
import Trainingsplaner

// Erfassung Kader: all rows are edited together and saved with one
// button; a wrong row stops the save; reopened for another attribute the
// dialog fits its own rows, not the last opening's
Item {
    width: 1200
    height: 800

    AttributeHistoryDialog {
        id: dialog
    }

    TestCase {
        name: "AttributeHistory"
        when: windowShown

        function rowsOf(item, out) {
            for (const c of item.children) {
                if (c.objectName === "historyRow")
                    out.push(c)
                rowsOf(c, out)
            }
            return out
        }

        function setText(field, text) {
            field.text = text
            field.textEdited()
        }

        function test_editSaveAndHeight() {
            compare(Store.saveAttributeHistory("test_tina", "Kader", [
                { from: "01.01.2030", to: "31.05.2030", text: "NK2" },
                { from: "01.06.2030", to: "", text: "NK1" },
                { from: "01.09.2030", to: "", text: "OK" },
            ]), "")
            dialog.edit("test_tina", "Kader")
            tryCompare(dialog, "opened", true)
            compare(rowsOf(dialog.contentItem, []).length, 3)
            compare(rowsOf(dialog.contentItem, []).map(r => findChild(r, "valueBox").editText).join(" "), "NK2 NK1 OK")
            verify(!dialog.dirty)
            waitForRendering(dialog.contentItem)
            const tall = dialog.height

            // Remove the last row, add one, fill it in
            mouseClick(findChild(rowsOf(dialog.contentItem, [])[2], "removeButton"))
            mouseClick(findChild(dialog.footer, "addButton"))
            tryVerify(() => rowsOf(dialog.contentItem, []).length === 3)
            const row = rowsOf(dialog.contentItem, [])[2]
            setText(findChild(row, "fromField"), "1.1.2031")
            findChild(row, "valueBox").editText = "PK"
            verify(dialog.dirty)

            // "bis" before "von": nothing is saved, the dialog stays open
            setText(findChild(rowsOf(dialog.contentItem, [])[0], "toField"), "01.01.2029")
            mouseClick(findChild(dialog.footer, "saveButton"))
            verify(dialog.error.startsWith("Zeile 1:"), dialog.error)
            verify(dialog.visible)
            compare(Store.attributeHistory("test_tina", "Kader").length, 3)

            setText(findChild(rowsOf(dialog.contentItem, [])[0], "toField"), "31.05.2030")
            mouseClick(findChild(dialog.footer, "saveButton"))
            compare(dialog.error, "")
            tryCompare(dialog, "visible", false)
            const saved = Store.attributeHistory("test_tina", "Kader")
            compare(saved.map(r => r.from + " " + r.text).join(", "),
                    "01.01.2030 NK2, 01.06.2030 NK1, 01.01.2031 PK")

            // Another attribute without records: one empty row, a lower dialog
            dialog.edit("test_tina", "Bundeswehr")
            tryCompare(dialog, "opened", true)
            compare(rowsOf(dialog.contentItem, []).length, 1)
            tryVerify(() => dialog.height < tall - 40)
            // Changed, Abbrechen asks first
            setText(findChild(rowsOf(dialog.contentItem, [])[0], "fromField"), "01.02.2031")
            mouseClick(findChild(dialog.footer, "cancelButton"))
            verify(dialog.visible)
            keyClick(Qt.Key_Escape)   // keep editing
            tryCompare(DialogStack, "open", 1)
            verify(dialog.visible)
            mouseClick(findChild(dialog.footer, "cancelButton"))
            tryCompare(DialogStack, "open", 2)
            const confirm = findChild(dialog, "discardConfirm")
            tryCompare(confirm, "opened", true)
            mouseClick(confirm.standardButton(Dialog.Discard))
            tryCompare(dialog, "visible", false)
            compare(Store.attributeHistory("test_tina", "Bundeswehr").length, 0)

            compare(Store.saveAttributeHistory("test_tina", "Kader", []), "")
        }

        // Many rows: the dialog stops at the window's height and scrolls,
        // the buttons stay below the rows; fewer rows: it shrinks again
        function test_scrollsAndShrinks() {
            dialog.edit("test_tina", "BSP")
            tryCompare(dialog, "opened", true)
            for (let i = 0; i < 24; ++i)
                dialog.addRow()
            tryVerify(() => dialog.height === dialog.parent.height - 40)
            const bar = dialog.contentItem.ScrollBar.vertical
            tryVerify(() => bar.visible && bar.size < 1)
            // The add button stays in view, below the scrolled rows, and the
            // rows are scrolled to the newest
            verify(findChild(dialog.footer, "addButton").visible)
            tryVerify(() => dialog.contentItem.atYEnd)
            const full = dialog.height
            for (let i = 0; i < 22; ++i)
                findChild(rowsOf(dialog.contentItem, [])[0], "removeButton").clicked()
            tryVerify(() => dialog.height < full - 300)
            verify(bar.size >= 1 || !bar.visible)
            dialog.dirty = false
            dialog.close()
            tryCompare(dialog, "visible", false)
        }
    }
}
