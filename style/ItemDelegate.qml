import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.ItemDelegate {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [ItemStyle.base, ItemStyle.delegate]
        styles: control.styles
        overrides: [control.highlighted ? ItemStyle.highlighted : null]
        state: !control.enabled ? StyleState.Disable
               : control.down ? StyleState.Active
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    topPadding: cascade.padding.top
    bottomPadding: cascade.padding.bottom
    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right
    spacing: cascade.spacing
    hoverEnabled: true
    opacity: cascade.opacity

    icon.width: cascade.icon.size
    icon.height: cascade.icon.size

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: control.display === IconLabel.IconOnly || control.display === IconLabel.TextUnderIcon
                   ? Qt.AlignCenter : Qt.AlignLeft

        icon.source: control.icon.source
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
    }
}
