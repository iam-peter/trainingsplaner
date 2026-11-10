import QtQuick
import Trainingsplaner
import QtQuick.Controls

// A button with a Lucide icon (icons/<iconName>.svg) and optional text.
Button {
    property string iconName
    property string toolTip

    icon.source: Theme.icon(iconName)
    icon.width: 16
    icon.height: 16
    display: text === "" ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon
    // Square when there is no text, instead of the style's minimum width;
    // whole pixels, as the style's
    implicitWidth: Math.ceil(text === ""
                             ? Math.max(implicitHeight, implicitContentWidth + leftPadding + rightPadding)
                             : Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                        implicitContentWidth + leftPadding + rightPadding))

    ToolTip.visible: toolTip !== "" && hovered
    ToolTip.text: toolTip
    ToolTip.delay: 500
}
