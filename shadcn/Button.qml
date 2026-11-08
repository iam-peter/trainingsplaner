import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// shadcn buttons: highlighted is "default" (filled), flat is "ghost", any
// other "outline". Dialog buttons get "default", "outline" or
// "destructive" from their role.
T.Button {
    id: control

    property string kind: highlighted ? "default" : flat ? "ghost" : "outline"
    readonly property bool hot: hovered && enabled

    readonly property color fill: {
        switch (kind) {
        case "default": return hot || down ? Tokens.alpha(Tokens.primary, 0.9) : Tokens.primary
        case "destructive": return Tokens.alpha(Tokens.destructive, (hot || down ? 0.9 : 1) * (Tokens.dark ? 0.6 : 1))
        case "secondary": return hot || down ? Tokens.alpha(Tokens.secondary, 0.8) : Tokens.secondary
        case "outline": return hot || down || checked ? (Tokens.dark ? Tokens.inputHover : Tokens.accent) : Tokens.dark ? Tokens.inputBackground : Tokens.background
        }
        return hot || down || checked ? (Tokens.dark ? Tokens.alpha(Tokens.accent, 0.5) : Tokens.accent) : "transparent"
    }
    readonly property color foreground: kind === "default" ? Tokens.primaryForeground
                                        : kind === "destructive" ? "#ffffff"
                                        : kind === "secondary" ? Tokens.secondaryForeground
                                        : hot ? Tokens.accentForeground : Tokens.foreground

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    leftPadding: text !== "" ? 12 : 8
    rightPadding: text !== "" ? 12 : 8
    spacing: 6
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5
    font.weight: Font.Medium

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
        implicitWidth: control.text !== "" ? 64 : Tokens.controlHeight
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusMd
        color: control.fill
        border.width: control.kind === "outline" ? 1 : 0
        border.color: control.visualFocus ? Tokens.ring : Tokens.dark ? Tokens.input : Tokens.border

        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 1
            visible: control.kind !== "ghost" && control.enabled
        }
        FocusRing {
            baseRadius: parent.radius
            visible: control.visualFocus
        }
    }
}
