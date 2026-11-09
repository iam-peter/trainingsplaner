import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A framed area with the program's border colour.
// filled: the base colour of a list instead of the window colour.
Frame {
    id: control

    property bool filled: false

    background: Rectangle {
        color: control.filled ? control.palette.base : "transparent"
        border.color: Theme.line
        radius: Theme.radius(4)
    }
}
