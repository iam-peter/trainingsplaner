import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.MenuItem {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [ItemStyle.base, ItemStyle.menuItem]
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
        icon.color: cascade.icon.color
        text: control.text
        font: control.font
        color: cascade.text.color
    }

    indicator: ColorImage {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.checked
        source: control.checkable ? "qrc:/qt/qml/TrainingsplanerStyle/images/check.svg" : ""
        sourceSize: Qt.size(16, 16)
        color: cascade.text.color
    }

    arrow: ColorImage {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        visible: control.subMenu
        mirror: control.mirrored
        source: control.subMenu ? "qrc:/qt/qml/TrainingsplanerStyle/images/chevron-right.svg" : ""
        sourceSize: Qt.size(16, 16)
        color: cascade.text.color
    }

    background: Rectangle {
        // A minimum only: entries are as wide as their text needs, and a
        // menu as wide as its longest entry
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        radius: cascade.radius.value
        color: cascade.background
    }
}
