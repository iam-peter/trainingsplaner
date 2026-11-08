import QtQuick
import QtQuick.Controls

// A toolbar of fixed height, so switching pages does not make the content
// jump, and with room above and below the buttons, so their hover
// background stays inside the toolbar's lines.
ToolBar {
    implicitHeight: 44
    topPadding: 0
    bottomPadding: 0
}
