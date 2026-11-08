import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A toolbar of fixed height, so switching pages does not make the content
// jump, and with room above and below the buttons, so their hover
// background stays inside the toolbar's lines. It draws its own plain
// background in every style: Material colours its toolbars in the primary
// colour with white text, which made our tab bars unreadable.
Pane {
    implicitHeight: Theme.toolBarHeight
    padding: 0

    background: Rectangle {
        color: Theme.window
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.line
        }
    }
}
