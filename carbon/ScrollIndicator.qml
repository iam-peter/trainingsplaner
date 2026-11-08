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
        color: Tokens.borderStrong
        visible: control.size < 1.0
        opacity: control.active ? 0.85 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
