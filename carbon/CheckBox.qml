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

    indicator: Rectangle {
        implicitWidth: 16
        implicitHeight: 16
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 2
        color: control.checkState !== Qt.Unchecked ? (control.enabled ? Tokens.iconPrimary : Tokens.textDisabled) : "transparent"
        border.width: 1
        border.color: control.enabled ? Tokens.iconPrimary : Tokens.textDisabled

        ColorImage {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/Carbon/images/check.svg"
            color: Tokens.iconInverse
            visible: control.checkState === Qt.Checked
        }
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 2
            color: Tokens.iconInverse
            visible: control.checkState === Qt.PartiallyChecked
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 3
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
