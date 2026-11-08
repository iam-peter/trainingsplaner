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

    padding: 6
    leftPadding: 16
    rightPadding: 16
    spacing: 8
    hoverEnabled: true

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
        icon.color: control.enabled ? Tokens.textPrimary : Tokens.textDisabled
        text: control.text
        font: control.font
        color: control.enabled ? Tokens.textPrimary : Tokens.textDisabled
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: Tokens.controlHeight
        color: control.down ? Tokens.layerActive
               : control.highlighted ? (control.hovered ? Tokens.layerSelectedHover : Tokens.layerSelected)
               : control.hovered ? Tokens.layerHover : "transparent"
        FocusRing {
            anchors.fill: parent
            visible: control.visualFocus
        }
    }
}
