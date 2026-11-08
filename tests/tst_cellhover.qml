import QtQuick
import QtTest
import Trainingsplaner

// Moving slowly over the lines of a session keeps the cell hovered: no
// pixel between two lines where the background changes
Item {
    width: 300
    height: 300

    SessionCell {
        id: cell
        x: 10
        y: 10
        width: 200
        height: 200
        session: ({
            from: "", note: "",
            entries: [
                { kind: 0, exercise: 7, line: "17 14 15 3/3", name: "Standreißen", stats: { empty: true } },
                { kind: 0, exercise: 13, line: "16 17 19 2/2", name: "Zug breit", stats: { empty: true } },
                { kind: 0, exercise: 30, line: "21 16 17 3/3", name: "Nackendrücken", stats: { empty: true } },
                { kind: 2, exercise: 0, line: "Athletik", text: "Athletik" }
            ]
        })
    }

    TestCase {
        name: "CellHover"
        when: windowShown

        function test_noGapBetweenLines() {
            waitForRendering(cell)
            for (let y = 18; y < 100; ++y) {
                mouseMove(cell, 60, y)
                verify(Qt.colorEqual(cell.color, Theme.cellHover), "not hovered at y " + y)
            }
            mouseMove(cell, 60, 250)   // outside
            verify(Qt.colorEqual(cell.color, Theme.cell))
        }
    }
}
