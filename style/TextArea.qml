import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TextArea {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [FieldStyle.base, FieldStyle.textArea]
        styles: control.styles
        overrides: [control.activeFocus && !control.readOnly ? FieldStyle.focus : null,
                    control.readOnly ? FieldStyle.readOnly : null]
        state: !control.enabled ? StyleState.Disable
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(contentWidth + leftPadding + rightPadding,
                            implicitBackgroundWidth + leftInset + rightInset,
                            placeholder.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(contentHeight + topPadding + bottomPadding,
                             implicitBackgroundHeight + topInset + bottomInset,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom
    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
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
        // One control high: a taller minimum made a text area in a lower
        // scroll view scroll with nothing in it
        implicitHeight: cascade.height
        radius: cascade.radius.value
        color: cascade.background
        border.width: cascade.border.width
        border.color: cascade.border.color
    }
}
