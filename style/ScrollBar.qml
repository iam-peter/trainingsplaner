import QtQuick
import QtQuick.Templates as T

T.ScrollBar {
    id: control

    StyleCascade {
        id: cascade
        base: [ScrollBarStyle.base]
        overrides: [control.interactive ? null : ScrollBarStyle.thin]
        state: control.pressed ? StyleState.Active
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }
    StyleCascade {
        id: thumb
        parentCascade: cascade
        part: StylePart.Handle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: cascade.padding.value
    visible: control.policy !== T.ScrollBar.AlwaysOff
    minimumSize: orientation === Qt.Horizontal ? height / width : width / height

    contentItem: Rectangle {
        implicitWidth: thumb.width
        implicitHeight: thumb.width
        radius: width / 2
        color: thumb.background
        opacity: control.policy === T.ScrollBar.AlwaysOn || (control.active && control.size < 1.0) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
