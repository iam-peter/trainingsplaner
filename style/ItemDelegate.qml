import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.ItemDelegate {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: Tokens.space2
    leftPadding: Tokens.space2
    rightPadding: Tokens.space2
    spacing: Tokens.space2
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    icon.width: 16
    icon.height: 16

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: control.display === IconLabel.IconOnly || control.display === IconLabel.TextUnderIcon
                   ? Qt.AlignCenter : Qt.AlignLeft

        icon.source: control.icon.source
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: Tokens.foreground
        text: control.text
        font: control.font
        color: Tokens.foreground
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusSm
        color: control.highlighted || control.down || control.hovered ? Tokens.accent : "transparent"
    }
}
