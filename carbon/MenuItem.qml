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

    padding: 6
    leftPadding: 16
    rightPadding: 16
    spacing: 8
    hoverEnabled: true

    icon.width: 16
    icon.height: 16

    readonly property color foreground: !enabled ? Tokens.textDisabled
                                        : highlighted ? Tokens.textPrimary : Tokens.textSecondary

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
        icon.color: control.foreground
        text: control.text
        font: control.font
        color: control.foreground
    }

    indicator: ColorImage {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.checked
        source: control.checkable ? "qrc:/qt/qml/Carbon/images/check.svg" : ""
        color: control.foreground
    }

    arrow: ColorImage {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.subMenu
        mirror: control.mirrored
        source: control.subMenu ? "qrc:/qt/qml/Carbon/images/chevron-right.svg" : ""
        color: control.foreground
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: Tokens.controlHeight
        color: control.down ? Tokens.layerActive : control.highlighted ? Tokens.layerHover : "transparent"
        FocusRing {
            anchors.fill: parent
            visible: control.visualFocus
        }
    }
}
