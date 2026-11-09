import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// A button: ButtonStyle.base with a variant. Pages pick one with styles,
// e.g. [ButtonStyle.ghost]; otherwise highlighted is primary, flat ghost
// and any other outline.
T.Button {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: _style

    StyleCascade {
        id: _style
        base: [ButtonStyle.base, ButtonStyle.variant(control.highlighted, control.flat)]
        styles: control.styles
        overrides: [control.visualFocus ? ButtonStyle.focus : null,
                    control.text === "" ? ButtonStyle.iconOnly : null]
        state: !control.enabled ? StyleState.Disable
               : control.down || control.checked ? StyleState.Active
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: _style.padding.top
    bottomPadding: _style.padding.bottom
    leftPadding: _style.padding.left
    rightPadding: _style.padding.right
    spacing: _style.spacing
    hoverEnabled: true
    opacity: _style.opacity
    font.weight: _style.text.weight

    icon.width: _style.icon.size
    icon.height: _style.icon.size

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon.source: control.icon.source
        icon.name: control.icon.name
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: _style.icon.color
        text: control.text
        font: control.font
        color: _style.text.color
    }

    background: Rectangle {
        implicitWidth: _style.width
        implicitHeight: _style.height
        radius: _style.radius.value
        color: _style.background
        border.width: _style.border.width
        border.color: _style.border.color
    }
}
