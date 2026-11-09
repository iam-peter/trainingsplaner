import QtQuick
import QtQuick.Controls

// A dialog footer whose buttons alone decide what happens. A Dialog
// closes itself as soon as a button with the Accept or Reject role in its
// own button box is clicked, before the button's handler runs, so a
// failed save could not keep it open and Abbrechen could not ask about
// changes first. Wrapped, the box keeps its roles (the order and look
// the style gives them), but the dialog does not see it.
Item {
    id: footer

    default property alias buttons: box.contentData
    // What AppDialog reads for its natural width
    readonly property alias count: box.count
    readonly property alias spacing: box.spacing
    readonly property alias leftPadding: box.leftPadding
    readonly property alias rightPadding: box.rightPadding
    function itemAt(i) { return box.itemAt(i) }

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight

    DialogButtonBox {
        id: box
        anchors.fill: parent
    }
}
