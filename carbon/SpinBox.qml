import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon number input: the value on the left, minus and plus on the right
T.SpinBox {
    id: control

    readonly property int stepWidth: Tokens.fieldHeight

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             up.implicitIndicatorHeight, down.implicitIndicatorHeight)

    leftPadding: 12
    rightPadding: 2 * stepWidth + 4
    hoverEnabled: true

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
        color: control.enabled ? Tokens.textPrimary : Tokens.textDisabled
        selectionColor: Tokens.highlight
        selectedTextColor: Tokens.textPrimary
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
    }

    down.indicator: Rectangle {
        x: control.mirrored ? control.stepWidth : control.width - 2 * control.stepWidth
        height: control.height
        implicitWidth: control.stepWidth
        implicitHeight: Tokens.fieldHeight
        color: control.down.pressed ? Tokens.layerActive : control.down.hovered ? Tokens.fieldHover : "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            color: enabled ? Tokens.iconPrimary : Tokens.textDisabled
        }
        // Divider between minus and plus
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 16
            color: Tokens.borderSubtle
        }
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : control.width - control.stepWidth
        height: control.height
        implicitWidth: control.stepWidth
        implicitHeight: Tokens.fieldHeight
        color: control.up.pressed ? Tokens.layerActive : control.up.hovered ? Tokens.fieldHover : "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            color: enabled ? Tokens.iconPrimary : Tokens.textDisabled
        }
        Rectangle {
            anchors.centerIn: parent
            width: 1.5
            height: 10
            color: enabled ? Tokens.iconPrimary : Tokens.textDisabled
        }
    }

    background: Rectangle {
        implicitWidth: 128
        implicitHeight: Tokens.fieldHeight
        color: control.hovered && control.enabled ? Tokens.fieldHover : Tokens.field
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: control.enabled ? Tokens.borderStrong : "transparent"
            visible: !control.activeFocus
        }
        FocusRing {
            anchors.fill: parent
            visible: control.activeFocus
        }
    }
}
