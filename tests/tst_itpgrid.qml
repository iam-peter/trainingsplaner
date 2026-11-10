import QtQuick
import QtTest
import Trainingsplaner

// The plan grid: the arrow keys move between the cells in all four
// directions, a cell is entered with its number selected
Item {
    width: 1200
    height: 800

    ItpGrid {
        id: grid
        anchors.fill: parent
        owner: "test_tina"
        fromMonday: Plan.mondayFromLabel("10/2029")
        weeks: 3
        exercises: [1, 3]
    }

    TestCase {
        name: "ItpGrid"
        when: windowShown

        function editorAt(r, c) {
            const item = findChild(grid, "itpTable").itemAtCell(Qt.point(c, r))
            return item ? item.editor : null
        }

        function test_arrowKeys() {
            const table = findChild(grid, "itpTable")
            waitForRendering(table)
            table.focusCell(1, 0)
            tryVerify(() => editorAt(1, 0) && editorAt(1, 0).activeFocus)
            keyClick(Qt.Key_Right)
            tryVerify(() => editorAt(1, 1).activeFocus)
            keyClick(Qt.Key_Down)
            tryVerify(() => editorAt(2, 1).activeFocus)
            keyClick(Qt.Key_Left)
            tryVerify(() => editorAt(2, 0).activeFocus)
            keyClick(Qt.Key_Up)
            tryVerify(() => editorAt(1, 0).activeFocus)
            // At the edge the focus stays
            keyClick(Qt.Key_Left)
            wait(50)
            verify(editorAt(1, 0).activeFocus)
        }

        // The editor's border meets the grid's lines: no gap to the line
        // above (the cell above draws it), its own lines below and right
        function test_editorMeetsTheLines() {
            const table = findChild(grid, "itpTable")
            waitForRendering(table)
            table.focusCell(1, 1)
            tryVerify(() => editorAt(1, 1) && editorAt(1, 1).activeFocus)
            const editor = editorAt(1, 1)
            const cell = editor.parent
            compare(editor.y, 0)
            compare(editor.height, cell.height - 1)
            compare(editor.width, cell.width - 1 - editor.x)
        }
    }
}
