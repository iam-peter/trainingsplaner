import QtQuick
import QtQuick.Controls

// The dialog all screens use. It dims the window behind it clearly, so it
// is obvious that the dialog has the focus. The dim layer is bound to the
// window size: Fusion's own dim kept the size the window had when the
// dialog opened and stayed behind as a faint rectangle after resizing.
Dialog {
    parent: Overlay.overlay
    modal: true

    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
    }
    Overlay.modeless: Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
    }
}
