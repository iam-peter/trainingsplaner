import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon buttons: highlighted is "primary", flat is "ghost", any other
// "tertiary" (outlined). Dialog buttons set kind to "secondary" or
// "primary" themselves.
T.Button {
    id: control

    property string kind: highlighted ? "primary" : flat ? "ghost" : "tertiary"
    readonly property bool hovered_: hovered && enabled

    readonly property color fill: {
        if (!enabled)
            return kind === "ghost" || kind === "tertiary" ? "transparent" : Tokens.buttonDisabled
        switch (kind) {
        case "primary": return down ? Tokens.buttonPrimaryActive : hovered_ ? Tokens.buttonPrimaryHover : Tokens.buttonPrimary
        case "secondary": return down ? Tokens.buttonSecondaryActive : hovered_ ? Tokens.buttonSecondaryHover : Tokens.buttonSecondary
        case "danger": return down ? "#750e13" : hovered_ ? Tokens.buttonDangerHover : Tokens.buttonDanger
        case "tertiary": return down ? Tokens.buttonTertiaryActive : hovered_ ? Tokens.buttonTertiaryHover : "transparent"
        }
        return down ? Tokens.layerActive : hovered_ || checked ? Tokens.layerHover : "transparent"
    }
    readonly property color foreground: {
        if (!enabled)
            return Tokens.textDisabled
        if (kind === "tertiary")
            return down || hovered_ ? Tokens.textInverse : Tokens.buttonTertiary
        if (kind === "ghost")
            return Tokens.textPrimary
        return Tokens.textOnColor
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    leftPadding: text !== "" ? 12 : 8
    rightPadding: text !== "" ? 12 : 8
    spacing: 8
    hoverEnabled: true

    icon.width: 16
    icon.height: 16

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignLeft | Qt.AlignVCenter

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
        implicitWidth: control.text !== "" ? 80 : Tokens.controlHeight
        implicitHeight: Tokens.controlHeight
        color: control.fill
        border.width: control.kind === "tertiary" ? 1 : 0
        border.color: control.enabled ? (control.down || control.hovered_ ? control.fill : Tokens.buttonTertiary)
                                      : Tokens.borderDisabled

        FocusRing {
            anchors.fill: parent
            visible: control.visualFocus
            // An inset line keeps the text readable on coloured buttons
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                color: "transparent"
                border.width: 1
                border.color: Tokens.focusInset
                visible: control.kind !== "ghost"
            }
        }
    }
}
