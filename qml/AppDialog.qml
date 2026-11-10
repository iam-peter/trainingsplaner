import QtQuick
import Trainingsplaner
import TrainingsplanerStyle as Styles
import QtQuick.Controls

// The dialog all screens use: modal, centred in the window, and the window
// behind it clearly dimmed, so it is obvious that the dialog has the focus.
// The dim layer is anchored to the overlay, so it always covers the whole
// window, also after resizing.
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
        // "Speichern" has the save icon everywhere, like the program's own
        // save buttons (emphasis comes from the styles, by the button's role)
        const save = standardButton(Dialog.Save)
        if (save) {
            save.icon.source = Theme.icon("save")
            save.icon.width = 16
            save.icon.height = 16
            // No colour: the style tints the icon in its own text colour
        }
    }
    Component.onCompleted: labelButtons()
    onStandardButtonsChanged: labelButtons()

    parent: Overlay.overlay
    anchors.centerIn: parent

    modal: true
    // Blocking: a click on the dimmed window does nothing (Qt's dialogs
    // close on it by default, losing what was entered); the dialog's
    // buttons or Esc close it
    closePolicy: Popup.CloseOnEscape
    focus: true

    // As high as its content, up to the window's height less 40 px; a
    // dialog whose content can be taller scrolls it (DialogScroll)
    height: Math.min(parent ? parent.height - 40 : 100000, implicitHeight)

    onAboutToShow: {
        nested = DialogStack.open > 0
        if (!counted) {
            DialogStack.open += 1
            counted = true
        }
        level = DialogStack.open
    }

    // Enter and Esc work from the moment the dialog shows, also before it
    // has the keyboard focus
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
        color: root.nested ? "transparent" : Styles.TokenInterface.semantics.dim
    }
}
