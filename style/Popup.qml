import QtQuick
import QtQuick.Templates as T

// A popover
T.Popup {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [PopupStyle.popover]
        styles: control.styles
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    padding: cascade.padding.value

    // Blocks the window behind it, without dimming it: a click outside
    // only closes it, and does not also press what lies below
    modal: true
    dim: false

    background: Rectangle {
        color: cascade.background
        radius: cascade.radius.value
        border.width: cascade.border.width
        border.color: cascade.border.color
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 3
        }
    }

    T.Overlay.modal: Rectangle {
        color: cascade.dim
    }
}
