import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A framed area. The border is drawn from the text colour, so it shows in
// every palette; Fusion's own frame can vanish in dark system themes.
// filled: the base colour of a list instead of the window colour.
Frame {
    id: control

    property bool filled: false

    background: Rectangle {
        color: control.filled ? control.palette.base : "transparent"
        border.color: Theme.line
        radius: 4
    }
}
