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
    // Tall enough for the delete button (24 px) with 2 px around it
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             28 + topInset + bottomInset)

    background: Rectangle {
        radius: Theme.radius(3)
        color: row.highlighted ? Theme.rowSelected
               : row.down ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.25))
               : row.hovered ? Qt.tint(row.palette.base, Qt.rgba(0.5, 0.5, 0.5, 0.12))
               : "transparent"
    }

    HoverHandler {
        id: rowHover
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
        // As high as the selection less 2 px above and below, at least
        // 24 px: the icon at its normal 16 px. Every padding is set, since
        // the styles set the sides on their own and squeezed the icon.
        // (A fixed small size made Material ignore the clicks.)
        height: row.height - row.topInset - row.bottomInset - 4
        width: height
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        iconName: "trash-2"
        icon.color: fg
        background: Rectangle {
            radius: Theme.radius(3)
            color: deleteButton.pressed ? Qt.rgba(deleteButton.fg.r, deleteButton.fg.g, deleteButton.fg.b, 0.24)
                   : deleteButton.hovered ? Qt.rgba(deleteButton.fg.r, deleteButton.fg.g, deleteButton.fg.b, 0.14)
                   : "transparent"
        }
        toolTip: row.deleteToolTip
        // The row's hover handler, not row.hovered: some styles (Material)
        // give the hover to the button itself, which then hid itself
        opacity: rowHover.hovered || row.highlighted ? 1 : 0
        enabled: opacity > 0
        onClicked: row.deleteRequested()
    }
}
