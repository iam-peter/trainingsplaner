import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls

// Menu entry that shows its keyboard shortcut on the right. The style
// draws the entry itself, so its text has the style's colours in every
// state; the shortcut takes the same colour, a little fainter.
MenuItem {
    id: item

    property string keys

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding
                            + (keys !== "" ? keyLabel.implicitWidth + 24 : 0))

    Label {
        id: keyLabel
        anchors.right: parent.right
        anchors.rightMargin: item.rightPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: item.keys !== ""
        text: item.keys
        font: item.font
        // Our styles name their text colour; the others draw menu text in
        // the window text colour (the style's own label colour cannot be
        // followed in a binding)
        color: item.styleCascade.text.color
        opacity: 0.6
    }
}
