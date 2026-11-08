import QtQuick
import QtQuick.Templates as T

// shadcn tooltip: the primary colour, small text
T.ToolTip {
    id: control

    x: parent ? (parent.width - implicitWidth) / 2 : 0
    y: -implicitHeight - 4

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    margins: 6
    topPadding: 6
    bottomPadding: 6
    leftPadding: 12
    rightPadding: 12
    font.pixelSize: 12

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    contentItem: Text {
        text: control.text
        font: control.font
        wrapMode: Text.Wrap
        color: Tokens.primaryForeground
    }

    background: Rectangle {
        color: Tokens.primary
        radius: Tokens.radiusMd
    }
}
