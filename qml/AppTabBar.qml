import QtQuick
import QtQuick.Controls
import Trainingsplaner

// Tabs as one flat segmented bar: all tabs the same height, the current
// one filled and underlined. Fusion's own tabs lower the unselected ones
// by two pixels, which leaves a step between them. With the Carbon style
// they are Carbon's contained tabs, with shadcn its tabs list.
TabBar {
    id: control

    spacing: 0
    padding: Theme.carbon ? 0 : Theme.shadcn ? 3 : 1

    background: Rectangle {
        color: Theme.carbon ? Theme.tokens.layerAccent : Theme.shadcn ? Theme.sh.muted : control.palette.button
        border.color: control.palette.mid
        border.width: Theme.carbon || Theme.shadcn ? 0 : 1
        radius: Theme.radius(4)
    }
}
