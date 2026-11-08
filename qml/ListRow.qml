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
    rightPadding: deleteButton.width + 8
    // Carbon's lists select the full width, shadcn's leave a little room
    leftInset: Theme.carbon ? 0 : Theme.shadcn ? 4 : 2
    rightInset: Theme.carbon ? 0 : Theme.shadcn ? 4 : 2
    topInset: Theme.carbon ? 0 : 1
    bottomInset: Theme.carbon ? 0 : 1

    background: Rectangle {
        radius: Theme.radius(3)
        color: row.highlighted ? Theme.rowSelected
               : row.down ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.25))
               : row.hovered ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.12))
               : "transparent"
    }

    IconToolButton {
        id: deleteButton
        objectName: "deleteButton"
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        iconName: "trash-2"
        icon.color: row.highlighted ? Theme.rowSelectedText : row.palette.buttonText
        toolTip: row.deleteToolTip
        opacity: row.hovered || row.highlighted ? 1 : 0
        enabled: opacity > 0
        onClicked: row.deleteRequested()
    }
}
