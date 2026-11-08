import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon toggle: green when on
T.Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 4
    spacing: 8

    indicator: Rectangle {
        implicitWidth: 48
        implicitHeight: 24
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 12
        color: !control.enabled ? Tokens.buttonDisabled : control.checked ? Tokens.supportSuccess : Tokens.toggleOff

        Rectangle {
            x: Math.max(3, Math.min(parent.width - width - 3,
                                    control.visualPosition * parent.width - width / 2))
            y: 3
            width: 18
            height: 18
            radius: 9
            color: control.enabled ? "#ffffff" : Tokens.textDisabled
            Behavior on x { enabled: !control.down; NumberAnimation { duration: 110 } }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 15
            color: "transparent"
            border.width: 2
            border.color: Tokens.focus
            visible: control.visualFocus
        }
    }

    contentItem: CheckLabel {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: control.enabled ? Tokens.textPrimary : Tokens.textDisabled
    }
}
