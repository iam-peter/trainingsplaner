import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The week × exercise grid of an ITP or a framework plan (RO).
Item {
    id: grid

    property alias model: itp
    property alias owner: itp.owner
    property alias fromMonday: itp.fromMonday
    property alias weeks: itp.weeks
    property alias exercises: itp.exercises
    property alias mazId: itp.mazId
    property alias averageAllWeeks: itp.averageAllWeeks

    ItpModel { id: itp }

    readonly property int cellWidth: 52
    readonly property int rowHeight: 28

    HorizontalHeaderView {
        id: header
        objectName: "itpHeader"
        anchors.left: table.left
        anchors.top: parent.top
        syncView: table
        clip: true
        delegate: Rectangle {
            required property int column
            // Read anew on every reload (percent is notified with it): a
            // reload keeps the headers, and a framework plan shows its
            // values as percent only once it has loaded
            readonly property var info: (itp.percent, itp.columnInfo(column))
            implicitWidth: grid.cellWidth
            implicitHeight: 40
            color: Styles.TokenInterface.semantics.background_default
            border.color: Styles.TokenInterface.semantics.stroke_subtle
            border.width: info.first ? 1 : 0
            ToolTip.visible: headerMouse.containsMouse
            ToolTip.text: info.tip
            MouseArea { id: headerMouse; anchors.fill: parent; hoverEnabled: true }
            Column {
                anchors.centerIn: parent
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: info.first ? info.title : ""
                    font.bold: true
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: info.sub
                    font.pixelSize: 11
                    color: Styles.TokenInterface.semantics.text_muted
                }
            }
        }
    }

    VerticalHeaderView {
        id: rows
        anchors.top: table.top
        anchors.left: parent.left
        syncView: table
        clip: true
        delegate: Rectangle {
            required property int row
            implicitWidth: 90
            implicitHeight: grid.rowHeight
            color: Styles.TokenInterface.semantics.background_default
            Rectangle { // row line, continued by the cells
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Styles.TokenInterface.semantics.stroke_subtle
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                // The phase letter comes from the MAZ: read anew on reload
                text: (itp.percent, itp.rowLabel(row))
                font.bold: row === itp.weeks
            }
        }
    }

    TableView {
        id: table
        objectName: "itpTable"
        anchors.left: rows.right
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: itp
        columnSpacing: 0
        rowSpacing: 0
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.horizontal: AppScrollBar { id: hbar }
        ScrollBar.vertical: AppScrollBar { id: vbar }
        // The bars beside the cells, not over the last row and column. A
        // fixed room: room that follows each bar would change the other
        // bar's size and so whether it shows (a binding loop); it only
        // shows once the grid scrolls, at its end.
        rightMargin: vbar.width + 4
        bottomMargin: hbar.height + 4
        // All columns alike, Bel. and WK too: the table estimates the room
        // of the columns it has not loaded from the average width, and
        // wider ones made it count room that is not there, so a bar stayed
        // when the window grew
        columnWidthProvider: () => grid.cellWidth

        // The cell being edited; only it has a text field. A field in
        // every cell made each reload of the grid take a quarter second.
        property point current: Qt.point(-1, -1)
        // A Tab into the grid enters its current cell, else the first.
        // Only when the table itself has the focus: it is a focus scope,
        // active too while its editor has the focus
        activeFocusOnTab: true
        onActiveFocusChanged: if (activeFocus && Window.activeFocusItem === table)
                                  focusCell(Math.max(0, current.y), Math.max(0, current.x))

        delegate: Rectangle {
            id: cell
            required property var model
            required property int row
            required property int column
            required property string display
            required property bool average
            readonly property bool first: itp.columnInfo(column).first
            readonly property bool editing: row === table.current.y && column === table.current.x
            readonly property Item editor: editorLoader.item
            implicitHeight: grid.rowHeight
            color: average ? Styles.TokenInterface.semantics.background_muted : Styles.TokenInterface.semantics.background_elevated
            // The grid: a line below and to the right of every cell, a
            // stronger one before each exercise
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Styles.TokenInterface.semantics.stroke_subtle
            }
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Styles.TokenInterface.semantics.stroke_subtle
            }
            Rectangle {
                visible: cell.first
                width: 1
                height: parent.height
                color: Styles.TokenInterface.semantics.stroke_subtle
            }
            // The number, and the editor over it: up to the cell's own
            // lines (below, right, and left before an exercise), not a
            // pixel short of the line above
            Item {
                id: area
                anchors.fill: parent
                anchors.bottomMargin: 1
                anchors.rightMargin: 1
                anchors.leftMargin: cell.first ? 1 : 0
            }
            Text {
                anchors.fill: area
                visible: !cell.editing
                text: cell.display
                font.bold: cell.average
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Styles.TokenInterface.semantics.text_default
            }
            TapHandler {
                enabled: !cell.average && !cell.editing
                onTapped: table.focusCell(cell.row, cell.column)
            }
            Loader {
                id: editorLoader
                anchors.fill: area
                active: cell.editing && !cell.average
                sourceComponent: editorComponent
            }
            // Scrolled out, the cell is used for another one: what was
            // typed is saved first
            TableView.onPooled: if (editor) editor.commit()

            Component {
                id: editorComponent
                TextField {
                    text: cell.display
                    horizontalAlignment: TextInput.AlignHCenter
                    // Without the focus (a click outside the grid) it looks like
                    // the other cells; a Tab into the grid comes back here
                    background: Rectangle {
                        color: parent.activeFocus ? Styles.TokenInterface.semantics.background_elevated : "transparent"
                        border.color: parent.activeFocus ? Styles.TokenInterface.semantics.primary_default : "transparent"
                    }
                    // WK-Lage: free text; Bel.: h, m, g (or a number); else numbers
                    validator: {
                        const title = itp.columnInfo(cell.column).title
                        return title === "WK" ? null : title === "Bel." ? loadValidator : intValidator
                    }
                    function commit() {
                        if (text !== cell.display)
                            cell.model.edit = text
                    }
                    onEditingFinished: commit()
                    Keys.onUpPressed: table.focusCell(cell.row - 1, cell.column)
                    Keys.onDownPressed: table.focusCell(cell.row + 1, cell.column)
                    // Left and right move the cursor inside the number first,
                    // then on to the next cell (a cell is entered all selected)
                    Keys.onLeftPressed: (event) => {
                        if (selectedText === text || cursorPosition === 0)
                            table.focusCell(cell.row, cell.column - 1)
                        else
                            event.accepted = false
                    }
                    Keys.onRightPressed: (event) => {
                        if (selectedText === text || cursorPosition === text.length)
                            table.focusCell(cell.row, cell.column + 1)
                        else
                            event.accepted = false
                    }
                    Keys.onReturnPressed: { commit(); table.focusCell(cell.row + 1, cell.column) }
                    // Tab goes on along the row, then to the next week's
                    // first cell; past the last cell it leaves the grid
                    Keys.onTabPressed: (event) => {
                        if (cell.column + 1 < table.columns)
                            table.focusCell(cell.row, cell.column + 1)
                        else if (cell.row + 1 < itp.weeks)
                            table.focusCell(cell.row + 1, 0)
                        else
                            event.accepted = false
                    }
                    Keys.onBacktabPressed: (event) => {
                        if (cell.column > 0)
                            table.focusCell(cell.row, cell.column - 1)
                        else if (cell.row > 0)
                            table.focusCell(cell.row - 1, table.columns - 1)
                        else
                            event.accepted = false
                    }
                }
            }
        }

        function focusCell(r, c) {
            if (r < 0 || r >= itp.weeks || c < 0 || c >= columns)
                return
            const before = itemAtCell(current)
            if (before && before.editor)
                before.editor.commit()
            current = Qt.point(c, r)
            positionViewAtCell(Qt.point(c, r), TableView.Contain)
            Qt.callLater(() => {
                const item = itemAtCell(Qt.point(c, r))
                if (item && item.editor) {
                    item.editor.forceActiveFocus()
                    item.editor.selectAll()
                }
            })
        }
    }

    IntValidator { id: intValidator; bottom: 0; top: 9999 }
    RegularExpressionValidator {
        id: loadValidator
        regularExpression: /^[hmgHMG]?$|^\d{0,2}$/
    }

    Label {
        anchors.centerIn: parent
        visible: itp.weeks === 0 || itp.owner === ""
        text: "Bitte Sportler und Zeitraum wählen."
        color: Styles.TokenInterface.semantics.text_muted
    }
}
