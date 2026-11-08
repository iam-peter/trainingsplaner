import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A row of a list with a delete button on its right, shown for the
// selected row and the one under the pointer.
ItemDelegate {
    id: row

    property string deleteToolTip: "Löschen"
    signal deleteRequested()

    width: ListView.view ? ListView.view.width : implicitWidth
    hoverEnabled: true
    rightPadding: deleteButton.width + 8

    IconToolButton {
        id: deleteButton
        objectName: "deleteButton"
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        iconName: "trash-2"
        icon.color: row.highlighted ? row.palette.highlightedText : row.palette.buttonText
        toolTip: row.deleteToolTip
        opacity: row.hovered || row.highlighted ? 1 : 0
        enabled: opacity > 0
        onClicked: row.deleteRequested()
    }
}
