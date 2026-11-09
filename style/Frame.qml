import QtQuick
import QtQuick.Templates as T

// A card
T.Frame {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    padding: Tokens.space4

    background: Rectangle {
        color: Tokens.card
        radius: Tokens.radiusXl
        border.color: Tokens.border
    }
}
