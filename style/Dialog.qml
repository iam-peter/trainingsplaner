import QtQuick
import QtQuick.Templates as T

// Dialog: a rounded, bordered card with a large shadow, the title
// in semibold, the buttons on the right
T.Dialog {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: _style

    StyleCascade {
        id: _style
        base: [PopupStyle.dialog]
        styles: control.styles
        overrides: [control.modal ? null : PopupStyle.modeless]
    }
    StyleCascade {
        id: _titleStyle
        parentCascade: _style
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

    leftPadding: _style.padding.left
    rightPadding: _style.padding.right
    topPadding: _style.padding.top
    bottomPadding: _style.padding.bottom

    background: Rectangle {
        color: _style.background
        radius: _style.radius.value
        border.width: _style.border.width
        border.color: _style.border.color
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
        font.pixelSize: _titleStyle.text.size
        font.weight: _titleStyle.text.weight
        color: _titleStyle.text.color
        leftPadding: _titleStyle.padding.left
        rightPadding: _titleStyle.padding.right
        topPadding: _titleStyle.padding.top
        bottomPadding: _titleStyle.padding.bottom
    }

    footer: DialogButtonBox {
        visible: count > 0
    }

    T.Overlay.modal: Rectangle {
        color: _style.dim
    }

    T.Overlay.modeless: Rectangle {
        color: _style.dim
    }
}
