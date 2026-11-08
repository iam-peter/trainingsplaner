import QtQuick
import QtQuick.Controls
import Trainingsplaner

// Tabs as one flat segmented bar: all tabs the same height, the current
// one filled and underlined. Fusion's own tabs lower the unselected ones
// by two pixels, which leaves a step between them. With the Carbon style
// they are Carbon's contained tabs.
TabBar {
    id: control

    spacing: 0
    padding: Theme.carbon ? 0 : 1

    background: Rectangle {
        color: Theme.carbon ? Theme.tokens.layerAccent : control.palette.button
        border.color: control.palette.mid
        border.width: Theme.carbon ? 0 : 1
        radius: Theme.radius(4)
    }
}
