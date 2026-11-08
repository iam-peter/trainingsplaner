import QtQuick
import QtTest
import Trainingsplaner

// The week plan works from the keyboard: arrows move between sessions,
// Enter opens one, Delete removes it after asking, Ctrl+←/→ change weeks.
Item {
    id: window
    width: 1300
    height: 900

    WeekPage {
        id: page
        anchors.fill: parent
    }

    TestCase {
        name: "WeekKeys"
        when: windowShown

        readonly property string monday: "2026-11-09"

        function cell(day, number) {
            return findChild(page, "cell" + day + "_" + number)
        }

        function init() {
            page.athleteId = "test_tina"
            page.monday = monday
            Store.saveSession("test_tina", monday, "P", {
                day: 2, number: 2, from: "", to: "", note: "",
                entries: [{ kind: 2, exercise: 0, text: "Dehnen" }]
            })
            waitForRendering(page)
        }

        function cleanup() {
            Store.removeSession("test_tina", monday, "P", 2, 2)
            compare(DialogStack.open, 0)
        }

        function test_arrowsMoveBetweenSessions() {
            page.focusSession(1, 1)
            verify(cell(1, 1).activeFocus)
            keyClick(Qt.Key_Right)
            verify(cell(2, 1).activeFocus)
            keyClick(Qt.Key_Down)
            verify(cell(2, 2).activeFocus)
            keyClick(Qt.Key_Down)   // no third row: stays
            verify(cell(2, 2).activeFocus)
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Left)   // stops at Monday
            verify(cell(1, 2).activeFocus)
        }

        function test_deleteAsksFirst() {
            page.focusSession(1, 2)
            keyClick(Qt.Key_Delete)   // empty session: nothing to ask
            compare(DialogStack.open, 0)
            page.focusSession(2, 2)
            keyClick(Qt.Key_Delete)
            tryCompare(DialogStack, "open", 1)
            keyClick(Qt.Key_Escape)   // No
            tryCompare(DialogStack, "open", 0)
            verify(page.sessionAt(2, 2) !== null)
            tryVerify(() => cell(2, 2).activeFocus)

            keyClick(Qt.Key_Delete)
            tryCompare(DialogStack, "open", 1)
            keyClick(Qt.Key_Return)   // Yes
            tryCompare(DialogStack, "open", 0)
            compare(page.sessionAt(2, 2), null)
        }

        function test_copyPasteAndUndo() {
            page.focusSession(2, 2)
            keyClick(Qt.Key_C, Qt.ControlModifier)
            page.focusSession(3, 1)
            keyClick(Qt.Key_V, Qt.ControlModifier)
            verify(page.sessionAt(3, 1) !== null)
            page.show(Store.undo())
            compare(page.sessionAt(3, 1), null)
        }

        function test_contextMenu() {
            const menu = findChild(page, "sessionMenu")
            verify(menu)
            mouseClick(cell(2, 2), 20, 40, Qt.RightButton)
            tryCompare(menu, "opened", true)
            compare(menu.day, 2)
            compare(menu.number, 2)
            keyClick(Qt.Key_Escape)
            tryCompare(menu, "visible", false)
            tryVerify(() => cell(2, 2).activeFocus)   // keys work again at once
        }

        function test_weeksAndDialogs() {
            page.focusSession(1, 1)
            keyClick(Qt.Key_Right, Qt.ControlModifier)
            compare(page.monday, "2026-11-16")
            keyClick(Qt.Key_Left, Qt.ControlModifier)
            compare(page.monday, monday)

            page.focusSession(2, 2)
            keyClick(Qt.Key_Return)
            tryCompare(DialogStack, "open", 1)
            // An open dialog keeps the week where it is
            keyClick(Qt.Key_Right, Qt.ControlModifier)
            compare(page.monday, monday)
            keyClick(Qt.Key_Escape)
            tryCompare(DialogStack, "open", 0)
        }
    }
}
