import QtQuick
import QtQuick.Controls
import Trainingsplaner

// Tabs as one flat segmented bar on a muted ground, the current tab
// raised on it.
TabBar {
    id: control

    spacing: 0
    // 28 px tabs in 2 px: as high as the fields beside it (32 px)
    padding: 2

    background: Rectangle {
        color: Theme.sh.muted
        radius: Theme.radius(4)
    }
}
