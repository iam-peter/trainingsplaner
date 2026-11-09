import QtQuick
import QtQuick.Templates as T

// Dialog: a rounded, bordered card with a large shadow, the title
// in semibold, the buttons on the right
T.Dialog {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [PopupStyle.dialog]
        styles: control.styles
        overrides: [control.modal ? null : PopupStyle.modeless]
    }
    StyleCascade {
        id: titleStyle
        parentCascade: cascade
        part: StylePart.Label
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom

    background: Rectangle {
        color: cascade.background
        radius: cascade.radius.value
        border.width: cascade.border.width
        border.color: cascade.border.color
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 4
        }
    }

    header: T.Label {
        text: control.title
        visible: parent?.parent === T.Overlay.overlay && control.title
        elide: Text.ElideRight
        font.pixelSize: titleStyle.text.size
        font.weight: titleStyle.text.weight
        color: titleStyle.text.color
        leftPadding: titleStyle.padding.left
        rightPadding: titleStyle.padding.right
        topPadding: titleStyle.padding.top
        bottomPadding: titleStyle.padding.bottom
    }

    footer: DialogButtonBox {
        visible: count > 0
    }

    T.Overlay.modal: Rectangle {
        color: cascade.dim
    }

    T.Overlay.modeless: Rectangle {
        color: cascade.dim
    }
}
