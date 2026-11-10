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
            const cell = table.itemAtCell(Qt.point(1, 1))
            const at = editor.mapToItem(cell, 0, 0)
            compare(at.y, 0)
            compare(editor.height, cell.height - 1)
            compare(editor.width, cell.width - 1 - at.x)
        }

        function displayAt(r, c) {
            const m = grid.model
            return m.data(m.index(r, c), Qt.DisplayRole)
        }

        // Tab runs along the week and on to the next one, Shift+Tab back;
        // a click opens a cell; leaving a cell saves what was typed
        function test_tabClickAndSave() {
            const table = findChild(grid, "itpTable")
            waitForRendering(table)
            const last = table.columns - 1
            table.focusCell(0, last)
            tryVerify(() => editorAt(0, last) && editorAt(0, last).activeFocus)
            keyClick(Qt.Key_Tab)
            tryVerify(() => editorAt(1, 0) && editorAt(1, 0).activeFocus)
            keyClick(Qt.Key_Backtab)
            tryVerify(() => editorAt(0, last) && editorAt(0, last).activeFocus)
            // Only the current cell has an editor
            verify(editorAt(1, 0) === null)
            // Back into the grid from outside (a Tab lands on the table):
            // the cell it was in
            table.parent.forceActiveFocus()
            verify(!editorAt(0, last).activeFocus)
            table.forceActiveFocus()
            tryVerify(() => editorAt(0, last) && editorAt(0, last).activeFocus)

            const cell = table.itemAtCell(Qt.point(0, 0))
            mouseClick(cell)
            tryVerify(() => editorAt(0, 0) && editorAt(0, 0).activeFocus)
            compare(editorAt(0, 0).selectedText, editorAt(0, 0).text)
            keyClick(Qt.Key_4)
            keyClick(Qt.Key_2)
            compare(editorAt(0, 0).text, "42")
            keyClick(Qt.Key_Tab)
            tryVerify(() => displayAt(0, 0) === "42")
            // Cleared again for the other tests
            table.focusCell(0, 0)
            tryVerify(() => editorAt(0, 0) && editorAt(0, 0).activeFocus)
            keyClick(Qt.Key_Delete)
            keyClick(Qt.Key_Tab)
            tryVerify(() => displayAt(0, 0) === "")
        }

        // A reload keeps the cells and the headers, which read their texts
        // anew: a framework plan's values are percent of the targets
        function test_headersFollowReload() {
            const r = Plan.saveMaz({ name: "Kopf-MAZ", shortName: "K", sex: 1, from: "10/2029", to: "12/2029",
                                     buildUp: "10/2029", peakPhase: "12/2029" })
            compare(r.error, "")
            const header = findChild(grid, "itpHeader")
            const table = findChild(grid, "itpTable")
            grid.owner = Plan.roOwner(r.id)
            grid.mazId = r.id
            tryVerify(() => header.itemAtCell(Qt.point(1, 0)) !== null)
            tryVerify(() => header.itemAtCell(Qt.point(1, 0)).info.sub.endsWith("%"))
            grid.mazId = ""
            grid.owner = "test_tina"
            tryVerify(() => !header.itemAtCell(Qt.point(1, 0)).info.sub.endsWith("%"))
            Plan.removeMaz(r.id)
        }
    }
}
