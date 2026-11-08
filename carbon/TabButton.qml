import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TabButton {
    id: control

    readonly property color foreground: !enabled ? Tokens.textDisabled
                                        : checked || hovered ? Tokens.textPrimary : Tokens.textSecondary

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

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

        icon.source: control.icon.source
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: control.foreground
        text: control.text
        font: control.font
        color: control.foreground
    }

    background: Item {
        implicitHeight: Tokens.controlHeight + 8
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: control.checked ? 2 : 1
            color: control.checked ? Tokens.borderInteractive
                   : control.hovered ? Tokens.borderStrong : Tokens.borderSubtle
        }
        FocusRing {
            anchors.fill: parent
            visible: control.visualFocus
        }
    }
}
