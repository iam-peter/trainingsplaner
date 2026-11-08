import QtQuick
import QtQuick.Controls
import Trainingsplaner

// One tab of an AppTabBar, optionally with a Lucide icon.
TabButton {
    id: control

    property string iconName

    implicitHeight: Theme.carbon ? 32 : 28
    // The program's font: some styles (Universal) make tabs much larger
    font: Qt.application.font
    icon.source: iconName !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + iconName + ".svg" : ""
    icon.color: palette.buttonText
    icon.width: 16
    icon.height: 16
    // The same position for every tab; Fusion moves unselected ones down
    topPadding: 4
    bottomPadding: 4

    background: Rectangle {
        radius: Theme.radius(3)
        color: control.checked ? (Theme.carbon ? Theme.tokens.background : control.palette.base)
               : control.hovered ? (Theme.carbon ? Theme.tokens.layerAccentHover
                                                 : Qt.tint(control.palette.button, Qt.rgba(0.5, 0.5, 0.5, 0.12)))
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
            color: Theme.carbon ? Theme.tokens.borderStrong : control.palette.mid
        }
        // The current tab is underlined in the accent colour; Carbon marks
        // it with a full-width line on top
        Rectangle {
            visible: control.checked
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: Theme.carbon ? undefined : parent.bottom
            anchors.top: Theme.carbon ? parent.top : undefined
            anchors.leftMargin: Theme.carbon ? 0 : 6
            anchors.rightMargin: Theme.carbon ? 0 : 6
            height: 2
            radius: Theme.radius(1)
            color: Theme.accent
        }
    }
}
