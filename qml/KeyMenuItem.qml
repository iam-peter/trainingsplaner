import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Menu entry that shows its keyboard shortcut on the right
MenuItem {
    id: item

    property string keys

    contentItem: RowLayout {
        spacing: 24
        Label {
            Layout.fillWidth: true
            text: item.text
            elide: Text.ElideRight
            color: item.highlighted ? item.palette.highlightedText : item.palette.windowText
        }
        Label {
            visible: item.keys !== ""
            text: item.keys
            color: item.highlighted ? item.palette.highlightedText : item.palette.placeholderText
        }
    }
}
