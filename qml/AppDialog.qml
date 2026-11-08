import QtQuick
import QtQuick.Controls

// The dialog all screens use: modal, centred in the window, and the window
// behind it clearly dimmed, so it is obvious that the dialog has the focus
// (Fusion's own dim is barely visible). The dim layer is anchored to the
// overlay, so it always covers the whole window, also after resizing.
// A dialog opened from another dialog does not add a second dim layer.
Dialog {
    id: root

    // Set while opening: another AppDialog is already open
    property bool nested: false
    property bool counted: false

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true

    onAboutToShow: {
        nested = DialogStack.open > 0
        if (!counted) {
            DialogStack.open += 1
            counted = true
        }
    }
    onClosed: {
        if (counted) {
            DialogStack.open -= 1
            counted = false
        }
    }
    Component.onDestruction: {
        if (counted)
            DialogStack.open -= 1
    }

    Overlay.modal: Rectangle {
        objectName: "dialogDim"
        anchors.fill: parent
        color: root.nested ? "transparent" : Qt.rgba(0, 0, 0, 0.45)
    }
}
