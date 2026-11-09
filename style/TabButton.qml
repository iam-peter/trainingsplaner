import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TabButton {
    id: control

    readonly property color foreground: checked ? Tokens.foreground : Tokens.tabInactiveText

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: Tokens.space1
    leftPadding: Tokens.space3
    rightPadding: Tokens.space3
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
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: control.foreground
        text: control.text
        font: control.font
        color: control.foreground
    }

    background: Rectangle {
        implicitHeight: 28
        radius: Tokens.radiusMd
        color: control.checked ? Tokens.tabActive : "transparent"
        border.width: control.checked || control.visualFocus ? 1 : 0
        border.color: control.visualFocus ? Tokens.ring : Tokens.tabActiveBorder
    }
}
