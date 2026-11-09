import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.RadioButton {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [ToggleStyle.base, ToggleStyle.radioButton]
        styles: control.styles
        overrides: [control.visualFocus ? ToggleStyle.focus : null]
        state: !control.enabled ? StyleState.Disable
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: cascade.padding.value
    spacing: cascade.spacing
    opacity: cascade.opacity

    indicator: Rectangle {
        implicitWidth: circle.width
        implicitHeight: circle.width
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: circle.radius.value
        color: circle.background
        border.width: circle.border.width
        border.color: circle.border.color

        StyleCascade {
            id: circle
            parentCascade: cascade
            part: StylePart.Indicator
        }

        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 4
            color: circle.accent
            visible: control.checked
        }
    }

    contentItem: CheckLabel {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: cascade.text.color
    }
}
