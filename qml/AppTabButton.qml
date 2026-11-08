import QtQuick
import QtQuick.Controls
import Trainingsplaner

// One tab of an AppTabBar, optionally with a Lucide icon.
TabButton {
    id: control

    property string iconName

    implicitHeight: 28
    icon.source: iconName !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + iconName + ".svg" : ""
    icon.color: palette.buttonText
    icon.width: 16
    icon.height: 16
    // The same position for every tab; Fusion moves unselected ones down
    topPadding: 4
    bottomPadding: 4

    background: Rectangle {
        radius: 3
        color: control.checked ? control.palette.base
                               : control.hovered ? Qt.tint(control.palette.button, Qt.rgba(0.5, 0.5, 0.5, 0.12))
                                                 : "transparent"

        // A divider before each unselected tab that does not follow the
        // selected one
        Rectangle {
            visible: control.TabBar.index > 0 && !control.checked
                     && control.TabBar.tabBar.currentIndex !== control.TabBar.index - 1
            x: -1
            y: 6
            width: 1
            height: parent.height - 12
            color: control.palette.mid
        }
        // The current tab is underlined in the accent colour
        Rectangle {
            visible: control.checked
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            height: 2
            radius: 1
            color: Theme.accent
        }
    }
}
