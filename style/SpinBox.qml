import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// An input with small minus and plus buttons inside on the right; each
// button is a part of the field's style with its own state
T.SpinBox {
    id: control

    property list<Style> styles
    readonly property alias cascade: cascade
    readonly property int stepWidth: upStyle.width

    StyleCascade {
        id: cascade
        base: [FieldStyle.base, FieldStyle.spinBox]
        styles: control.styles
        overrides: [control.activeFocus ? FieldStyle.focus : null]
        state: !control.enabled ? StyleState.Disable
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             up.implicitIndicatorHeight, down.implicitIndicatorHeight)

    leftPadding: cascade.padding.left
    rightPadding: 2 * stepWidth + 2 * Primitives.spacing.sp050
    hoverEnabled: true
    opacity: cascade.opacity

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
        color: cascade.text.color
        selectionColor: cascade.selection
        selectedTextColor: cascade.selectedText
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
    }

    down.indicator: Rectangle {
        id: downIndicator
        x: control.mirrored ? control.stepWidth + Primitives.spacing.sp050
                            : control.width - 2 * control.stepWidth - Primitives.spacing.sp050
        y: (control.height - height) / 2
        implicitWidth: downStyle.width
        implicitHeight: downStyle.width
        radius: downStyle.radius.value
        color: downStyle.background

        StyleCascade {
            id: downStyle
            parentCascade: cascade
            part: StylePart.Indicator
            state: !downIndicator.enabled ? StyleState.Disable
                   : control.down.pressed ? StyleState.Active
                   : control.down.hovered ? StyleState.Hover : StyleState.Idle
        }

        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            radius: 1
            color: downStyle.text.color
        }
    }

    up.indicator: Rectangle {
        id: upIndicator
        x: control.mirrored ? Primitives.spacing.sp050 : control.width - control.stepWidth - Primitives.spacing.sp050
        y: (control.height - height) / 2
        implicitWidth: upStyle.width
        implicitHeight: upStyle.width
        radius: upStyle.radius.value
        color: upStyle.background

        StyleCascade {
            id: upStyle
            parentCascade: cascade
            part: StylePart.Indicator
            state: !upIndicator.enabled ? StyleState.Disable
                   : control.up.pressed ? StyleState.Active
                   : control.up.hovered ? StyleState.Hover : StyleState.Idle
        }

        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 1.5
            radius: 1
            color: upStyle.text.color
        }
        Rectangle {
            anchors.centerIn: parent
            width: 1.5
            height: 10
            radius: 1
            color: upStyle.text.color
        }
    }

    background: Rectangle {
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        radius: cascade.radius.value
        color: cascade.background
        border.width: cascade.border.width
        border.color: cascade.border.color
    }
}
