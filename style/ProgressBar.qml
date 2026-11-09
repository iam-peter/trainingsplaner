import QtQuick
import QtQuick.Templates as T

T.ProgressBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 8
        clip: true
        Rectangle {
            width: control.indeterminate ? parent.width / 4 : control.visualPosition * parent.width
            height: parent.height
            radius: 4
            color: Tokens.primary
            NumberAnimation on x {
                running: control.indeterminate && control.visible
                loops: Animation.Infinite
                from: -control.width / 4
                to: control.width
                duration: 1400
            }
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 8
        y: (control.height - height) / 2
        height: 8
        radius: 4
        color: Tokens.alpha(Tokens.primary, 0.2)
    }
}
