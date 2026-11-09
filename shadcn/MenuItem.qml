import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.MenuItem {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: Tokens.space2
    leftPadding: Tokens.space2
    rightPadding: Tokens.space2
    spacing: Tokens.space2
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    icon.width: 16
    icon.height: 16

    readonly property color foreground: highlighted ? Tokens.accentForeground : Tokens.foreground

    contentItem: IconLabel {
        readonly property real arrowPadding: control.subMenu && control.arrow ? control.arrow.width + control.spacing : 0
        readonly property real indicatorPadding: control.checkable && control.indicator ? control.indicator.width + control.spacing : 0
        leftPadding: !control.mirrored ? indicatorPadding : arrowPadding
        rightPadding: control.mirrored ? indicatorPadding : arrowPadding

        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignLeft

        icon.source: control.icon.source
        icon.width: control.icon.width
        icon.height: control.icon.height
        icon.color: Tokens.mutedForeground
        text: control.text
        font: control.font
        color: control.foreground
    }

    indicator: ColorImage {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.checked
        source: control.checkable ? "qrc:/qt/qml/Shadcn/images/check.svg" : ""
        sourceSize: Qt.size(16, 16)
        color: control.foreground
    }

    arrow: ColorImage {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.subMenu
        mirror: control.mirrored
        source: control.subMenu ? "qrc:/qt/qml/Shadcn/images/chevron-right.svg" : ""
        sourceSize: Qt.size(16, 16)
        color: control.foreground
    }

    background: Rectangle {
        implicitWidth: 192
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusSm
        color: control.highlighted || control.down ? Tokens.accent : "transparent"
    }
}
