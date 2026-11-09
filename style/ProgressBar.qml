import QtQuick
import QtQuick.Templates as T

T.ProgressBar {
    id: control

    property list<Style> styles

    StyleCascade {
        id: cascade
        base: [ProgressBarStyle.base]
        styles: control.styles
    }
    StyleCascade {
        id: track
        parentCascade: cascade
        part: StylePart.Track
    }
    StyleCascade {
        id: progress
        parentCascade: cascade
        part: StylePart.Progress
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentItem: Item {
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        clip: true
        Rectangle {
            width: control.indeterminate ? parent.width / 4 : control.visualPosition * parent.width
            height: parent.height
            radius: cascade.radius.value
            color: progress.background
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
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        y: (control.height - height) / 2
        height: cascade.height
        radius: cascade.radius.value
        color: track.background
    }
}
