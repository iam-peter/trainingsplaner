import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// An input with small minus and plus buttons inside on the right
T.SpinBox {
    id: control

    readonly property int stepWidth: 26

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             up.implicitIndicatorHeight, down.implicitIndicatorHeight)

    leftPadding: 10
    rightPadding: 2 * stepWidth + 6
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    validator: IntValidator {
        locale: control.locale.name
        bottom: Math.min(control.from, control.to)
        top: Math.max(control.from, control.to)
    }

    contentItem: TextInput {
        z: 2
        text: control.displayText
        clip: width < implicitWidth
        font: control.font
        color: Tokens.foreground
        selectionColor: Tokens.primary
        selectedTextColor: Tokens.primaryForeground
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
    }

    down.indicator: Rectangle {
        x: control.mirrored ? control.stepWidth + 3 : control.width - 2 * control.stepWidth - 3
        y: (control.height - height) / 2
        implicitWidth: control.stepWidth
        implicitHeight: control.stepWidth
        radius: Tokens.radiusSm
        color: control.down.pressed || control.down.hovered ? Tokens.accent : "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            radius: 1
            color: enabled ? Tokens.foreground : Tokens.mutedForeground
        }
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 3 : control.width - control.stepWidth - 3
        y: (control.height - height) / 2
        implicitWidth: control.stepWidth
        implicitHeight: control.stepWidth
        radius: Tokens.radiusSm
        color: control.up.pressed || control.up.hovered ? Tokens.accent : "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            radius: 1
            color: enabled ? Tokens.foreground : Tokens.mutedForeground
        }
        Rectangle {
            anchors.centerIn: parent
            width: 1.5
            height: 10
            radius: 1
            color: enabled ? Tokens.foreground : Tokens.mutedForeground
        }
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusMd
        color: Tokens.inputBackground
        border.color: control.activeFocus ? Tokens.ring : Tokens.input
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 1
        }
        FocusRing {
            baseRadius: parent.radius
            visible: control.activeFocus
        }
    }
}
