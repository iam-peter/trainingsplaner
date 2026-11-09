import QtQuick
import QtQuick.Controls
import Trainingsplaner

// One tab of an AppTabBar, optionally with a Lucide icon.
TabButton {
    id: control

    property string iconName

    implicitHeight: 28
    font: Qt.application.font
    icon.source: iconName !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + iconName + ".svg" : ""
    icon.color: palette.buttonText
    icon.width: 16
    icon.height: 16
    topPadding: 4
    bottomPadding: 4

    background: Rectangle {
        radius: Theme.radius(3)
        // The current tab has a border in dark mode, and focus shows in
        // the border
        border.width: (Theme.dark && control.checked) || control.visualFocus ? 1 : 0
        border.color: control.visualFocus ? Theme.sh.ring : Theme.sh.input
        color: control.checked ? (Theme.dark ? Theme.sh.inputBackground : Theme.sh.background) : "transparent"
    }
}
