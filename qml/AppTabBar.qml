import QtQuick
import QtQuick.Controls
import Trainingsplaner

// Tabs as one flat segmented bar on a muted ground, the current tab
// raised on it.
TabBar {
    id: control

    spacing: 0
    padding: 4

    background: Rectangle {
        color: Theme.sh.muted
        radius: Theme.radius(4)
    }
}
