import QtQuick
import QtQuick.Controls
import TrainingsplanerStyle as Styles
import Trainingsplaner

// A row of a list with a delete button on its right, shown for the
// selected row and the one under the pointer. Selection and hover are
// rounded and inset, so they fit the rounded border of the list.
ItemDelegate {
    id: row

    property string deleteToolTip: "Löschen"
    signal deleteRequested()

    // The chosen row in the accent grey, the one under the pointer tinted
    styles: [Styles.ItemStyle.listRow]

    // Beside the list's scroll bar while it shows
    width: ListView.view ? ListView.view.width - (ListView.view.ScrollBar.vertical?.room ?? 0) : implicitWidth
    hoverEnabled: true
    // The selection leaves a little room to the list's border; the text
    // keeps 8 px to the selection
    leftInset: Theme.rowInsetX
    rightInset: Theme.rowInsetX
    topInset: Theme.rowInsetY
    bottomInset: Theme.rowInsetY
    leftPadding: Theme.rowInsetX + 8
    rightPadding: deleteButton.width + Theme.rowInsetX + 8
    // Tall enough for the delete button (24 px) with 2 px around it
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             28 + topInset + bottomInset)


    HoverHandler {
        id: rowHover
    }

    // Inside the row's background, with a hover of its own that also shows
    // on a selected row (in its text colour, faintly)
    IconToolButton {
        id: deleteButton
        objectName: "deleteButton"
        styles: [Styles.ButtonStyle.inline]
        anchors.right: parent.right
        anchors.rightMargin: Theme.rowInsetX + 2
        anchors.verticalCenter: parent.verticalCenter
        // As high as the selection less 2 px above and below, at least
        // 24 px: the icon at its normal 16 px. Every padding is set, so
        // nothing squeezes the icon.
        height: row.height - row.topInset - row.bottomInset - 4
        width: height
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        iconName: "trash-2"
        toolTip: row.deleteToolTip
        // The row's hover handler, not row.hovered: the button takes the
        // row's hover while the pointer is on it, and would hide itself
        opacity: rowHover.hovered || row.highlighted ? 1 : 0
        enabled: opacity > 0
        onClicked: row.deleteRequested()
    }
}
