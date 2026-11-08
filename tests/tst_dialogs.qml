import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

Item {
    id: root
    width: 600
    height: 400

    AppDialog {
        id: dialog
        title: "Test"
        width: 300
        height: 200
        anchors.centerIn: parent
    }

    TestCase {
        name: "Dialogs"
        when: windowShown

        function dimmer() {
            const overlay = dialog.Overlay.overlay
            for (let i = 0; i < overlay.children.length; ++i) {
                const c = overlay.children[i]
                if (c.color !== undefined && c.visible && Math.abs(c.color.a - 0.45) < 0.01)
                    return c
            }
            return null
        }

        function test_dimFollowsWindowSize() {
            dialog.open()
            tryCompare(dialog, "opened", true)
            const d = dimmer()
            verify(d, "a clear dim layer behind the dialog")
            compare(d.width, root.Window.window.width)

            // The window grows while the dialog is open
            root.Window.window.width = 1000
            root.Window.window.height = 700
            tryCompare(d, "width", 1000)
            tryCompare(d, "height", 700)
            // and the dialog stays centred
            tryCompare(dialog, "x", 350)

            dialog.close()
            tryCompare(dialog, "visible", false)
        }
    }
}
