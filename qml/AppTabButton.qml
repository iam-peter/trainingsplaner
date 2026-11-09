import QtQuick
import QtQuick.Controls
import Trainingsplaner
import TrainingsplanerStyle as Styles

// One tab of an AppTabBar, optionally with a Lucide icon: the style's tab
// as a segment of the bar (TabStyle.segment)
TabButton {
    id: control

    property string iconName

    styles: [Styles.TabStyle.segment]
    icon.source: iconName !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + iconName + ".svg" : ""
}
