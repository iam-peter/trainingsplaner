import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Dropdown menu: a popover with rounded items
T.Menu {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [PopupStyle.menu]
        styles: control.styles
    }

    // Blocks the window behind it, without dimming it: a click outside
    // only closes it, and does not also press what lies below
    modal: true
    dim: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    margins: 0
    overlap: 1
    padding: cascade.padding.value

    delegate: MenuItem {}

    contentItem: ListView {
        implicitHeight: contentHeight
        model: control.contentModel
        interactive: Window.window ? contentHeight + control.topPadding + control.bottomPadding > control.height : false
        clip: true
        currentIndex: control.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator {}
    }

    background: Rectangle {
        implicitWidth: cascade.width
        implicitHeight: cascade.height
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
