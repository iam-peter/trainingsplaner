import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Input: bordered, rounded, the focus colour on the border when focused
T.TextField {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [FieldStyle.base, FieldStyle.textField]
        styles: control.styles
        overrides: [control.activeFocus && !control.readOnly ? FieldStyle.focus : null,
                    control.readOnly ? FieldStyle.readOnly : null,
                    control.width > 0 && control.width < 64 ? FieldStyle.narrow : null]
        state: !control.enabled ? StyleState.Disable
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    // With the normal padding, not the actual one, which depends on the width
    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + 24
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom
    verticalAlignment: TextInput.AlignVCenter
    hoverEnabled: true
    opacity: cascade.opacity

    color: cascade.text.color
    selectionColor: cascade.selection
    selectedTextColor: cascade.selectedText
    placeholderTextColor: cascade.placeholder

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
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        radius: cascade.radius.value
        color: cascade.background
        border.width: cascade.border.width
        border.color: cascade.border.color
    }
}
