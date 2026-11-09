import QtQuick
import QtQuick.Templates as T

T.ScrollIndicator {
    id: control

    StyleCascade {
        id: cascade
        base: [ScrollBarStyle.base]
        overrides: [ScrollBarStyle.thin]
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

    contentItem: Rectangle {
        implicitWidth: thumb.width
        implicitHeight: thumb.width
        radius: width / 2
        color: thumb.background
        visible: control.size < 1.0
        opacity: control.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
