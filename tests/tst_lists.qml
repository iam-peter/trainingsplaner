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

        function test_searchAndRowDelete() {
            const id = Store.saveAthlete({ lastName: "Zweite", firstName: "Zoe", sex: 1 })
            page.select("test_tina")
            const search = findChild(page, "searchField")
            search.text = "zwei"
            compare(page.shown.length, 1)
            compare(page.shown[0].id, id)

            waitForRendering(page)
            const row = rowOf(page, "Zweite")
            verify(row)
            const button = findChild(row, "deleteButton")
            mouseMove(row, 20, row.height / 2)
            tryVerify(() => button.enabled)
            // Near the button's right edge, where a hidden scroll bar once
            // took the click
            mouseClick(button, button.width - 3, button.height / 2)
            tryCompare(DialogStack, "open", 1)
            keyClick(Qt.Key_Return)   // Ja
            tryCompare(DialogStack, "open", 0)
            verify(!Store.athletes.some(a => a.id === id))
            compare(page.selectedId, "test_tina")   // still editing Tina
            search.text = ""
        }
    }
}
