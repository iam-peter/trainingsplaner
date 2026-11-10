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
        anchors.left: table.left
        anchors.top: parent.top
        syncView: table
        clip: true
        delegate: Rectangle {
            required property int column
            readonly property var info: itp.columnInfo(column)
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
                text: itp.rowLabel(row)
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
        columnWidthProvider: column => itp.columnInfo(column).sub === "" ? 60 : grid.cellWidth

        delegate: Rectangle {
            id: cell
            required property var model
            required property int row
            required property int column
            required property string display
            required property bool average
            readonly property alias editor: _editor
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
                visible: itp.columnInfo(cell.column).first
                width: 1
                height: parent.height
                color: Styles.TokenInterface.semantics.stroke_subtle
            }
            Label {
                anchors.centerIn: parent
                visible: cell.average
                text: cell.display
                font.bold: true
            }
            TextField {
                id: _editor
                // Up to the cell's own lines (below, right, and left before
                // an exercise), not a pixel short of the line above
                anchors.fill: parent
                anchors.bottomMargin: 1
                anchors.rightMargin: 1
                anchors.leftMargin: itp.columnInfo(cell.column).first ? 1 : 0
                visible: !cell.average
                text: cell.display
                horizontalAlignment: TextInput.AlignHCenter
                background: Rectangle { color: parent.activeFocus ? Styles.TokenInterface.semantics.background_elevated : "transparent"; border.color: parent.activeFocus ? Styles.TokenInterface.semantics.primary_default : "transparent" }
                validator: itp.columnInfo(cell.column).title === "WK" ? null : intValidator
                onEditingFinished: if (text !== cell.display) cell.model.edit = text
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
                Keys.onReturnPressed: { editingFinished(); table.focusCell(cell.row + 1, cell.column) }
            }
        }

        function focusCell(r, c) {
            if (r < 0 || r >= itp.weeks || c < 0 || c >= columns)
                return
            positionViewAtCell(Qt.point(c, r), TableView.Contain)
            Qt.callLater(() => {
                const item = itemAtCell(Qt.point(c, r))
                if (item) {
                    item.editor.forceActiveFocus()
                    item.editor.selectAll()
                }
            })
        }
    }

    IntValidator { id: intValidator; bottom: 0; top: 9999 }

    Label {
        anchors.centerIn: parent
        visible: itp.weeks === 0 || itp.owner === ""
        text: "Bitte Sportler und Zeitraum wählen."
        color: Styles.TokenInterface.semantics.text_muted
    }
}
