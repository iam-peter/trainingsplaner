import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// A tool button: ButtonStyle.tool, a ghost button that is square without
// text; styles can choose another variant.
T.ToolButton {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [ButtonStyle.base, ButtonStyle.tool]
        styles: control.styles
        overrides: [control.visualFocus ? ButtonStyle.focus : null,
                    control.text === "" || control.display === T.AbstractButton.IconOnly
                    ? ButtonStyle.iconOnly : null]
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
