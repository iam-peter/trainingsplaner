import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TextArea {
    id: control

    implicitWidth: Math.max(contentWidth + leftPadding + rightPadding,
                            implicitBackgroundWidth + leftInset + rightInset,
                            placeholder.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(contentHeight + topPadding + bottomPadding,
                             implicitBackgroundHeight + topInset + bottomInset,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 11
    leftPadding: 12
    rightPadding: 12
    hoverEnabled: true

    color: enabled ? Tokens.textPrimary : Tokens.textDisabled
    selectionColor: Tokens.highlight
    selectedTextColor: Tokens.textPrimary
    placeholderTextColor: enabled ? Tokens.textPlaceholder : Tokens.textDisabled

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: control.readOnly ? "transparent" : control.hovered && control.enabled ? Tokens.fieldHover : Tokens.field

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
            visible: control.activeFocus && !control.readOnly
        }
    }
}
