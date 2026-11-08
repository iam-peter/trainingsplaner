import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// What the dialogs must do, and what Fusion's plain Dialog did not: dim the
// window clearly, dim it only once when a dialog opens another, and stay
// centred and fully dimmed when the window is resized.
Item {
    id: root
    width: 600
    height: 400

    AppDialog {
        id: outer
        title: "Außen"
        width: 300
        height: 200
    }

    AppDialog {
        id: inner
        title: "Innen"
        width: 200
        height: 100
    }

    // One button and text that grows after creation: made a binding loop
    AppDialog {
        id: message
        property alias text: messageLabel.text
        title: "Hinweis"
        standardButtons: Dialog.Ok
        Label { id: messageLabel }
    }

    AppDialog {
        id: question
        title: "Frage"
        standardButtons: Dialog.Yes | Dialog.No | Dialog.Cancel
    }

    TestCase {
        name: "Dialogs"
        when: windowShown

        function dims() {
            const overlay = outer.Overlay.overlay
            const list = []
            for (let i = 0; i < overlay.children.length; ++i) {
                const c = overlay.children[i]
                if (c.objectName === "dialogDim" && c.visible)
                    list.push(c)
            }
            return list
        }

        function cleanup() {
            inner.close()
            outer.close()
            tryCompare(outer, "visible", false)
            // Some styles let the inner dialog fade out a little longer
            tryCompare(DialogStack, "open", 0)
        }

        function test_clearDim() {
            outer.open()
            tryCompare(outer, "opened", true)
            const d = dims()
            compare(d.length, 1)
            // Clearly visible, not Fusion's faint shade
            verify(d[0].color.a >= 0.4, "dim alpha " + d[0].color.a)
            compare(d[0].width, root.Window.window.width)
        }

        function test_followsResize() {
            outer.open()
            tryCompare(outer, "opened", true)
            root.Window.window.width = 1000
            root.Window.window.height = 700
            const d = dims()[0]
            tryCompare(d, "width", 1000)
            tryCompare(d, "height", 700)
            tryCompare(outer, "x", 350)   // centred in the window, not in its declaring item
            tryCompare(outer, "y", 250)
        }

        function test_singleButtonGrowsWithoutLoop() {
            failOnWarning(/Binding loop/)
            message.text = "Ein deutlich längerer Text, der den Dialog breiter macht als vorher"
            message.open()
            tryCompare(message, "opened", true)
            verify(message.width >= messageLabel.implicitWidth)
            message.close()
            tryCompare(message, "visible", false)
        }

        function test_germanButtons() {
            compare(question.standardButton(Dialog.Yes).text, "Ja")
            compare(question.standardButton(Dialog.No).text, "Nein")
            compare(question.standardButton(Dialog.Cancel).text, "Abbrechen")
            question.standardButtons = Dialog.Close
            compare(question.standardButton(Dialog.Close).text, "Schließen")
        }

        function test_nestedDialogDimsOnce() {
            outer.open()
            tryCompare(outer, "opened", true)
            inner.open()
            tryCompare(inner, "opened", true)
            compare(DialogStack.open, 2)
            const visibleDims = dims().filter(d => d.color.a > 0)
            compare(visibleDims.length, 1)
            inner.close()
            tryCompare(inner, "visible", false)
            compare(DialogStack.open, 1)
            // Reopened on its own, the inner dialog dims again
            outer.close()
            tryCompare(outer, "visible", false)
            inner.open()
            tryCompare(inner, "opened", true)
            verify(!inner.nested)
            compare(dims().filter(d => d.color.a > 0).length, 1)
        }
    }
}
