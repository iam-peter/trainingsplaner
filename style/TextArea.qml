import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TextArea {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: _style

    StyleCascade {
        id: _style
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

    topPadding: _style.padding.top
    bottomPadding: _style.padding.bottom
    leftPadding: _style.padding.left
    rightPadding: _style.padding.right
    hoverEnabled: true
    opacity: _style.opacity

    color: _style.text.color
    selectionColor: _style.selection
    selectedTextColor: _style.selectedText
    placeholderTextColor: _style.placeholder

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
        implicitWidth: _style.width
        // One control high: a taller minimum made a text area in a lower
        // scroll view scroll with nothing in it
        implicitHeight: _style.height
        radius: _style.radius.value
        color: _style.background
        border.width: _style.border.width
        border.color: _style.border.color
    }
}
