import QtQuick
import TrainingsplanerStyle as Styles
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
        color: control.filled ? Styles.TokenInterface.semantics.background_elevated : "transparent"
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        radius: Styles.Primitives.radius.r4
    }
}
