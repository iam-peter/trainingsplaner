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

    // The natural width from the title text and the buttons themselves,
    // not from the title label and the button row: the styles size those
    // from the dialog's width (a lone button gets half of it), so taking
    // their natural widths made a binding loop whenever the content grew.
    TextMetrics {
        id: titleMetrics
        font: root.header ? root.header.font : root.font
        text: root.title
    }
    readonly property real titleWidth: root.title === "" || !root.header ? 0
        : titleMetrics.advanceWidth + root.header.leftPadding + root.header.rightPadding + 2
    readonly property real buttonsWidth: {
        const box = footer
        if (!box || !box.visible || box.count === undefined || box.count === 0)
            return 0
        let w = 0
        let n = 0
        for (let i = 0; i < box.count; ++i) {
            const it = box.itemAt(i)
            if (it && it.visible) {
                w += it.implicitWidth
                ++n
            }
        }
        // The styles give a lone button the right half of the row
        if (n === 1)
            w *= 2
        return w + Math.max(0, n - 1) * box.spacing + box.leftPadding + box.rightPadding
    }
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            titleWidth,
                            buttonsWidth)
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

    // Enter and Esc work from the moment the dialog shows, also while a
    // style (Material, Fluent) still animates it in and the dialog does not
    // have the keyboard focus yet
    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.visible && root.enterAccepts && root.level === DialogStack.open
        onActivated: root.accept()
    }
    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.visible && (root.closePolicy & Popup.CloseOnEscape) && root.level === DialogStack.open
        onActivated: root.reject()
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
        color: root.nested ? "transparent" : Theme.dim
    }
}
