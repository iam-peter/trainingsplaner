import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A dialog that edits something and saves it with its own buttons: dirty
// marks unsaved changes, and Abbrechen (cancel()) or Esc asks before they
// are thrown away. The question opens on top; the editor stays open
// behind it until Verwerfen. askDiscard() asks the same before something
// else that loses the changes (another exercise), with what to do then.
AppDialog {
    id: editor

    property bool dirty: false
    property string discardText: "Die Änderungen wurden noch nicht gespeichert."
    // The editor's own keys only while no other dialog is above it
    readonly property bool onTop: visible && level === DialogStack.open

    property var afterDiscard: null
    property var afterKeep: null

    function askDiscard(then, keep) {
        afterDiscard = then || null
        afterKeep = keep || null
        discardConfirm.open()
    }

    function cancel() {
        if (dirty)
            askDiscard()
        else
            close()
    }

    closePolicy: Popup.NoAutoClose

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: editor.onTop
        onActivated: editor.cancel()
    }

    // A property, not a child: children of this dialog land in the content
    // item it starts with, which a derived dialog replaces, leaving them
    // outside the window
    property AppDialog discardConfirm: AppDialog {
        objectName: "discardConfirm"
        parent: editor.parent
        title: "Änderungen verwerfen?"
        standardButtons: Dialog.Discard | Dialog.Cancel
        Label { text: editor.discardText }
        onDiscarded: {
            editor.discardConfirm.close()
            const then = editor.afterDiscard
            editor.afterDiscard = null
            editor.afterKeep = null
            editor.dirty = false
            if (then)
                then()
            else
                editor.close()
        }
        onRejected: {
            const keep = editor.afterKeep
            editor.afterDiscard = null
            editor.afterKeep = null
            if (keep)
                keep()
        }
    }
}
