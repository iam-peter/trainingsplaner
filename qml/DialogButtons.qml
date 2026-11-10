import QtQuick
import QtQuick.Controls
import TrainingsplanerStyle as Styles

// A dialog footer whose buttons alone decide what happens. A Dialog
// closes itself as soon as a button with the Accept or Reject role in its
// own button box is clicked, before the button's handler runs, so a
// failed save could not keep it open and Abbrechen could not ask about
// changes first. Wrapped, the box keeps its roles (the order and look
// the style gives them), but the dialog does not see it.
// leading: buttons at the left end, away from the others (TE löschen); a
// Destructive role makes them red there too.
Item {
    id: footer

    default property alias buttons: box.contentData
    property alias leading: leadingRow.data
    implicitWidth: box.implicitWidth
                   + (leadingRow.implicitWidth > 0 ? leadingRow.implicitWidth + 2 * box.spacing : 0)
    implicitHeight: box.implicitHeight

    DialogButtonBox {
        id: box
        anchors.fill: parent
    }

    Row {
        id: leadingRow
        x: box.leftPadding
        y: box.topPadding
        spacing: box.spacing
        Component.onCompleted: {
            for (const it of children) {
                if (it.styles !== undefined && it.DialogButtonBox.buttonRole === DialogButtonBox.DestructiveRole)
                    it.styles = [Styles.ButtonStyle.destructive]
            }
        }
    }
}
