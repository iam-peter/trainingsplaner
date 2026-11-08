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

        function test_searchAndRowDelete() {
            const id = Store.saveAthlete({ lastName: "Zweite", firstName: "Zoe", sex: 1 })
            page.select("test_tina")
            const search = findChild(page, "searchField")
            search.text = "zwei"
            compare(page.shown.length, 1)
            compare(page.shown[0].id, id)

            waitForRendering(page)
            const button = findChild(page, "deleteButton")
            const row = button.parent
            mouseMove(row, 20, row.height / 2)
            tryVerify(() => button.enabled)
            mouseClick(button)
            tryCompare(DialogStack, "open", 1)
            keyClick(Qt.Key_Return)   // Ja
            tryCompare(DialogStack, "open", 0)
            verify(!Store.athletes.some(a => a.id === id))
            compare(page.selectedId, "test_tina")   // still editing Tina
            search.text = ""
        }
    }
}
