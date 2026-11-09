import QtQuick
import QtTest
import Trainingsplaner

// The athletes list: search, and deleting from a row without changing
// the athlete being edited
Item {
    width: 1200
    height: 800

    AthletesPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "Lists"
        when: windowShown

        // The list row (in the scene) whose text starts with the name
        function rowOf(item, name) {
            for (const c of item.children) {
                if (c.objectName === "deleteButton" && c.parent.text.startsWith(name) && c.parent.visible)
                    return c.parent
                const r = rowOf(c, name)
                if (r)
                    return r
            }
            return null
        }

        // The texts of all list rows with a delete button
        function rows(item, out) {
            for (const c of item.children) {
                if (c.objectName === "deleteButton")
                    out.push(c.parent.text + (c.parent.visible ? "" : " (hidden)"))
                rows(c, out)
            }
            return out
        }

        function test_searchAndRowDelete() {
            const id = Store.saveAthlete({ lastName: "Zweite", firstName: "Zoe", sex: 1 })
            page.select("test_tina")
            const search = findChild(page, "searchField")
            search.text = "zwei"
            compare(page.shown.length, 1)
            compare(page.shown[0].id, id)

            waitForRendering(page)
            // Zoe's own row: the first delete button found can be on a row
            // of the list before the search that is not destroyed yet (it
            // made the Windows nightly click Tina's, under Material)
            const row = rowOf(page, "Zweite")
            verify(row)
            const button = findChild(row, "deleteButton")
            mouseMove(row, 20, row.height / 2)
            tryVerify(() => button.enabled)
            mouseClick(button)
            // What the button was like, should the click open nothing (seen
            // only on Windows under Material, so far)
            const pos = button.mapToItem(page, 0, 0)
            const state = "enabled " + button.enabled + ", opacity " + button.opacity
                          + ", hovered " + button.hovered + ", pressed " + button.pressed
                          + ", size " + button.width + "x" + button.height
                          + ", at " + Math.round(pos.x) + "," + Math.round(pos.y)
                          + ", row " + row.text + " " + row.width + "x" + row.height
                          + ", rows " + rows(page, []).join(" | ")
            tryVerify(() => DialogStack.open === 1, 5000, "no dialog after the click: " + state)
            keyClick(Qt.Key_Return)   // Ja
            tryCompare(DialogStack, "open", 0)
            verify(!Store.athletes.some(a => a.id === id))
            compare(page.selectedId, "test_tina")   // still editing Tina
            search.text = ""
        }
    }
}
