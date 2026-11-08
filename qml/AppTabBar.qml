import QtQuick
import QtQuick.Controls

// Tabs as one flat segmented bar: all tabs the same height, the current
// one filled and underlined. Fusion's own tabs lower the unselected ones
// by two pixels, which leaves a step between them.
TabBar {
    id: control

    spacing: 0
    padding: 1

    background: Rectangle {
        color: control.palette.button
        border.color: control.palette.mid
        radius: 4
    }
}
