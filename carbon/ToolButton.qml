import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon ghost button
T.ToolButton {
    id: control

    readonly property color foreground: enabled ? Tokens.textPrimary : Tokens.textDisabled

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    leftPadding: text !== "" && display !== T.AbstractButton.IconOnly ? 12 : 8
    rightPadding: leftPadding
    spacing: 8
    hoverEnabled: true

    icon.width: 16
    icon.height: 16

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon.source: control.icon.source
        icon.name: control.icon.name
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: control.foreground
        text: control.text
        font: control.font
        color: control.foreground
    }

    background: Rectangle {
        implicitWidth: Tokens.controlHeight
        implicitHeight: Tokens.controlHeight
        color: control.down ? Tokens.layerActive
               : control.checked ? Tokens.layerSelected
               : control.hovered && control.enabled ? Tokens.layerHover : "transparent"
        FocusRing {
            anchors.fill: parent
            visible: control.visualFocus
        }
    }
}
