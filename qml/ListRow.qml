import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A row of a list with a delete button on its right, shown for the
// selected row and the one under the pointer. Selection and hover are
// rounded and inset, so they fit the rounded border of the list.
ItemDelegate {
    id: row

    property string deleteToolTip: "Löschen"
    signal deleteRequested()

    width: ListView.view ? ListView.view.width : implicitWidth
    hoverEnabled: true
    // Carbon's lists select the full width, shadcn's leave a little room;
    // the text keeps 8 px to the selection in shadcn
    leftInset: Theme.rowInsetX
    rightInset: Theme.rowInsetX
    topInset: Theme.rowInsetY
    bottomInset: Theme.rowInsetY
    leftPadding: Theme.shadcn ? Theme.rowInsetX + 8 : undefined
    rightPadding: deleteButton.width + Theme.rowInsetX + 8

    background: Rectangle {
        radius: Theme.radius(3)
        color: row.highlighted ? Theme.rowSelected
               : row.down ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.25))
               : row.hovered ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.12))
               : "transparent"
    }

    // Inside the row's background, with a hover of its own that also shows
    // on a selected row (in its text colour, faintly)
    IconToolButton {
        id: deleteButton
        objectName: "deleteButton"
        readonly property color fg: row.highlighted ? Theme.rowSelectedText : row.palette.buttonText
        anchors.right: parent.right
        anchors.rightMargin: Theme.rowInsetX + 2
        anchors.verticalCenter: parent.verticalCenter
        height: row.height - row.topInset - row.bottomInset - 4
        width: height
        padding: 0
        iconName: "trash-2"
        icon.color: fg
        background: Rectangle {
            radius: Theme.radius(3)
            color: deleteButton.pressed ? Qt.rgba(deleteButton.fg.r, deleteButton.fg.g, deleteButton.fg.b, 0.24)
                   : deleteButton.hovered ? Qt.rgba(deleteButton.fg.r, deleteButton.fg.g, deleteButton.fg.b, 0.14)
                   : "transparent"
        }
        toolTip: row.deleteToolTip
        opacity: row.hovered || row.highlighted ? 1 : 0
        enabled: opacity > 0
        onClicked: row.deleteRequested()
    }
}
