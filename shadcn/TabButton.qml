import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TabButton {
    id: control

    readonly property color foreground: checked ? Tokens.foreground
                                        : Tokens.dark ? Tokens.mutedForeground : Tokens.foreground

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 4
    leftPadding: 10
    rightPadding: 10
    spacing: 6
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
        color: control.checked ? (Tokens.dark ? Tokens.inputBackground : Tokens.background) : "transparent"
        border.width: control.checked && Tokens.dark ? 1 : 0
        border.color: Tokens.input
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 1
            visible: control.checked
        }
        FocusRing {
            baseRadius: parent.radius
            visible: control.visualFocus
        }
    }
}
