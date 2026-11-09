import QtQuick
import QtQuick.Templates as T

// Tooltip: the primary colour, small text
T.ToolTip {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [PopupStyle.toolTip]
        styles: control.styles
    }

    x: parent ? (parent.width - implicitWidth) / 2 : 0
    y: -implicitHeight - 4

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    margins: cascade.spacing
    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom
    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
    font.pixelSize: cascade.text.size

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    contentItem: Text {
        text: control.text
        font: control.font
        wrapMode: Text.Wrap
        color: cascade.text.color
    }

    background: Rectangle {
        color: cascade.background
        radius: cascade.radius.value
    }
}
