import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.CheckBox {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [ToggleStyle.base, ToggleStyle.checkBox]
        styles: control.styles
        overrides: [control.visualFocus ? ToggleStyle.focus : null,
                    control.checkState !== Qt.Unchecked ? ToggleStyle.checkBoxChecked : null]
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
        implicitWidth: box.width
        implicitHeight: box.width
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: box.radius.value
        color: box.background
        border.width: box.border.width
        border.color: box.border.color

        StyleCascade {
            id: box
            parentCascade: cascade
            part: StylePart.Indicator
        }

        ColorImage {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/TrainingsplanerStyle/images/check.svg"
            sourceSize: Qt.size(14, 14)
            color: box.accent
            visible: control.checkState === Qt.Checked
        }
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 2
            radius: 1
            color: box.accent
            visible: control.checkState === Qt.PartiallyChecked
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
