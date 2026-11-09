import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A framed area with the program's border colour.
// filled: the base colour of a list instead of the window colour.
// Content keeps 8 px inside the 1 px border, like the buttons below the
// lists in the list panels (padding 1, the list up to the border).
Frame {
    id: control

    property bool filled: false

    padding: 9

    background: Rectangle {
        color: control.filled ? control.palette.base : "transparent"
        border.color: Theme.line
        radius: Theme.radius(4)
    }
}
