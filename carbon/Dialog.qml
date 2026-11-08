import QtQuick
import QtQuick.Templates as T

// Carbon modal: title in the heading style, buttons flush across the
// bottom edge
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

    padding: 16
    topPadding: 8
    bottomPadding: 24

    background: Rectangle {
        // One layer above the page, so its fields stand out
        color: Tokens.layer02
    }

    header: T.Label {
        text: control.title
        visible: parent?.parent === T.Overlay.overlay && control.title
        elide: Text.ElideRight
        font.pixelSize: 20
        color: Tokens.textPrimary
        leftPadding: 16
        rightPadding: 48
        topPadding: 16
        bottomPadding: 8
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
