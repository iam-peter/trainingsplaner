import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Ghost button
T.ToolButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: Tokens.space2
    // One control height with text, like the fields
    topPadding: 6
    bottomPadding: 6
    leftPadding: text !== "" && display !== T.AbstractButton.IconOnly ? Tokens.space3 : Tokens.space2
    rightPadding: leftPadding
    spacing: Tokens.space2
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5
    font.weight: Font.Medium

    icon.width: 16
    icon.height: 16

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon.source: control.icon.source
        icon.name: control.icon.name
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: Tokens.foreground
        text: control.text
        font: control.font
        color: Tokens.foreground
    }

    background: Rectangle {
        implicitWidth: Tokens.controlHeight
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusMd
        border.width: control.visualFocus ? 1 : 0
        border.color: Tokens.ring
        color: control.down || control.checked || (control.hovered && control.enabled)
               ? Tokens.ghostHover : "transparent"
    }
}
