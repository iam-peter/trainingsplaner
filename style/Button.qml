import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// A button: ButtonStyle.base with a variant. Pages pick one with styles,
// e.g. [ButtonStyle.ghost]; otherwise highlighted is primary, flat ghost
// and any other outline.
T.Button {
    id: control

    property list<Style> styles
    readonly property alias cascade: cascade

    StyleCascade {
        id: cascade
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

    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom
    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
    spacing: cascade.spacing
    hoverEnabled: true
    opacity: cascade.opacity
    font.weight: cascade.text.weight

    icon.width: cascade.icon.size
    icon.height: cascade.icon.size

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon.source: control.icon.source
        icon.name: control.icon.name
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: cascade.icon.color
        text: control.text
        font: control.font
        color: cascade.text.color
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
