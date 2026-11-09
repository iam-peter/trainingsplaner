import QtQuick
import QtQuick.Controls

// A flat tool button with a Lucide icon (icons/<iconName>.svg).
ToolButton {
    property string iconName
    property string toolTip

    icon.source: iconName !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + iconName + ".svg" : ""
    icon.width: 16
    icon.height: 16
    display: text === "" ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon

    ToolTip.visible: toolTip !== "" && hovered
    ToolTip.text: toolTip
    ToolTip.delay: 500
}
