import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 4
    spacing: 8
    opacity: enabled ? 1 : 0.5

    indicator: Rectangle {
        implicitWidth: 32
        implicitHeight: 18
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: height / 2
        color: control.checked ? Tokens.primary : Tokens.input
        border.width: control.visualFocus ? 1 : 0
        border.color: Tokens.ring

        Rectangle {
            x: Math.max(1, Math.min(parent.width - width - 1, control.visualPosition * parent.width - width / 2))
            y: 1
            width: 16
            height: 16
            radius: 8
            color: Tokens.dark ? (control.checked ? Tokens.primaryForeground : Tokens.foreground) : Tokens.background
            Behavior on x { enabled: !control.down; NumberAnimation { duration: 110 } }
        }
    }

    contentItem: CheckLabel {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: Tokens.foreground
    }
}
