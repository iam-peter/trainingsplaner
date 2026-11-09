import QtQuick
import QtQuick.Templates as T

T.ScrollIndicator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 2

    contentItem: Rectangle {
        implicitWidth: 2
        implicitHeight: 2
        radius: 1
        color: Tokens.scrollThumb
        visible: control.size < 1.0
        opacity: control.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
