import QtQuick
import QtQuick.Templates as T

// Dialog: a rounded, bordered card with a large shadow, the title
// in semibold, the buttons on the right
T.Dialog {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    padding: Tokens.space4
    topPadding: Tokens.space2
    bottomPadding: Tokens.space4

    background: Rectangle {
        color: Tokens.background
        radius: Tokens.radiusLg
        border.color: Tokens.border
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
        font.pixelSize: 18
        font.weight: Font.DemiBold
        color: Tokens.foreground
        leftPadding: Tokens.space4
        rightPadding: Tokens.space4
        topPadding: Tokens.space4
        bottomPadding: Tokens.space2
    }

    footer: DialogButtonBox {
        visible: count > 0
    }

    T.Overlay.modal: Rectangle {
        color: Tokens.overlay
    }

    T.Overlay.modeless: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.12)
    }
}
