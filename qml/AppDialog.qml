import QtQuick
import QtQuick.Controls

// The dialog all screens use: modal, centred in the window, and the window
// behind it clearly dimmed, so it is obvious that the dialog has the focus
// (Fusion's own dim is barely visible). The dim layer is anchored to the
// overlay, so it always covers the whole window, also after resizing.
// A dialog opened from another dialog does not add a second dim layer.
// The dialog takes the keyboard focus, so Esc closes it, and Enter answers
// Yes/OK in a dialog that asks for that. The standard buttons are labelled
// in German without depending on Qt's translation files being installed.
Dialog {
    id: root

    // Set while opening: another AppDialog is already open
    property bool nested: false
    property bool counted: false
    // Position in the stack of open dialogs; the topmost one takes Enter
    property int level: 0
    readonly property bool enterAccepts: (standardButtons & (Dialog.Yes | Dialog.Ok)) !== 0

    function labelButtons() {
        const labels = [[Dialog.Ok, "OK"], [Dialog.Cancel, "Abbrechen"], [Dialog.Yes, "Ja"],
                        [Dialog.No, "Nein"], [Dialog.Close, "Schließen"], [Dialog.Save, "Speichern"],
                        [Dialog.Discard, "Verwerfen"], [Dialog.Apply, "Anwenden"]]
        for (const [which, text] of labels) {
            const button = standardButton(which)
            if (button)
                button.text = text
        }
    }
    Component.onCompleted: labelButtons()
    onStandardButtonsChanged: labelButtons()

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    focus: true

    onAboutToShow: {
        nested = DialogStack.open > 0
        if (!counted) {
            DialogStack.open += 1
            counted = true
        }
        level = DialogStack.open
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.opened && root.enterAccepts && root.level === DialogStack.open
        onActivated: root.accept()
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
