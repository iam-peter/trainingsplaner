import QtQuick
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
            color: palette.window
            border.color: palette.mid
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
                    color: palette.placeholderText
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
            color: palette.window
            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: itp.rowLabel(row)
                font.bold: row === itp.weeks
            }
        }
    }

    TableView {
        id: table
        anchors.left: rows.right
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: itp
        columnSpacing: 0
        rowSpacing: 0
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.horizontal: ScrollBar {}
        ScrollBar.vertical: ScrollBar {}
        columnWidthProvider: column => itp.columnInfo(column).sub === "" ? 60 : grid.cellWidth

        delegate: Rectangle {
            id: cell
            required property var model
            required property int row
            required property int column
            required property string display
            required property bool average
            implicitHeight: grid.rowHeight
            color: average ? palette.alternateBase : palette.base
            border.color: palette.mid
            border.width: 0
            Rectangle { // column group separator
                visible: itp.columnInfo(cell.column).first
                width: 1
                height: parent.height
                color: palette.mid
            }
            Label {
                anchors.centerIn: parent
                visible: cell.average
                text: cell.display
                font.bold: true
            }
            TextField {
                anchors.fill: parent
                anchors.margins: 1
                visible: !cell.average
                text: cell.display
                horizontalAlignment: TextInput.AlignHCenter
                background: Rectangle { color: parent.activeFocus ? palette.base : "transparent"; border.color: parent.activeFocus ? palette.highlight : "transparent" }
                validator: itp.columnInfo(cell.column).title === "WK" ? null : intValidator
                onEditingFinished: if (text !== cell.display) cell.model.edit = text
                Keys.onUpPressed: table.focusCell(cell.row - 1, cell.column)
                Keys.onDownPressed: table.focusCell(cell.row + 1, cell.column)
                Keys.onReturnPressed: { editingFinished(); table.focusCell(cell.row + 1, cell.column) }
            }
        }

        function focusCell(r, c) {
            if (r < 0 || r >= itp.weeks)
                return
            positionViewAtCell(Qt.point(c, r), TableView.Contain)
            Qt.callLater(() => {
                const item = itemAtCell(Qt.point(c, r))
                if (item)
                    item.children[2].forceActiveFocus()
            })
        }
    }

    IntValidator { id: intValidator; bottom: 0; top: 9999 }

    Label {
        anchors.centerIn: parent
        visible: itp.weeks === 0 || itp.owner === ""
        text: "Bitte Sportler und Zeitraum wählen."
        color: palette.placeholderText
    }
}
