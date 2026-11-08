import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon text input: a filled field with a bottom border, the focus ring
// replaces the border while editing
T.TextField {
    id: control

    // With the normal padding, not the actual one, which depends on the width
    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + 24
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    // Narrow fields (a number of reps) keep room for their text
    leftPadding: width > 0 && width < 64 ? 3 : 12
    rightPadding: leftPadding
    topPadding: 6
    bottomPadding: 6
    verticalAlignment: TextInput.AlignVCenter
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
        implicitWidth: 160
        implicitHeight: Tokens.fieldHeight
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
