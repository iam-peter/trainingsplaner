import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.CheckBox {
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
        implicitWidth: 16
        implicitHeight: 16
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: Tokens.radiusMd
        color: control.checkState !== Qt.Unchecked ? Tokens.primary : Tokens.inputBackground
        border.color: control.checkState !== Qt.Unchecked ? Tokens.primary
                      : control.visualFocus ? Tokens.ring : Tokens.input

        ColorImage {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/Shadcn/images/check.svg"
            sourceSize: Qt.size(14, 14)
            color: Tokens.primaryForeground
            visible: control.checkState === Qt.Checked
        }
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 2
            radius: 1
            color: Tokens.primaryForeground
            visible: control.checkState === Qt.PartiallyChecked
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
