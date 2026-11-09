import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import Trainingsplaner

// A toolbar of fixed height, so switching pages does not make the content
// jump, and with room above and below the buttons, so their hover
// background stays inside the toolbar's lines.
Pane {
    implicitHeight: Theme.toolBarHeight
    padding: 0

    background: Rectangle {
        color: Styles.TokenInterface.semantics.background_default
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Styles.TokenInterface.semantics.stroke_subtle
        }
    }
}
