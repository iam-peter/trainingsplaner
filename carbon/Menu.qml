import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon overflow menu
T.Menu {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    margins: 0
    overlap: 1
    padding: 0

    delegate: MenuItem {}

    contentItem: ListView {
        implicitHeight: contentHeight
        model: control.contentModel
        interactive: Window.window ? contentHeight + control.topPadding + control.bottomPadding > control.height : false
        clip: true
        currentIndex: control.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator {}
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: Tokens.controlHeight
        color: Tokens.layer01
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -4
            anchors.leftMargin: -1
            anchors.rightMargin: -1
            color: Tokens.shadow
            opacity: 0.35
        }
    }

    T.Overlay.modal: Rectangle {
        color: Tokens.overlay
    }
}
