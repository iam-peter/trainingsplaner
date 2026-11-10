import QtQuick
import QtQuick.Controls

// The content of a dialog that can be taller than the window: as high as
// its one child, which anchors itself left and right; beyond the dialog's
// height it scrolls. The bar stands in the dialog's right padding: inside,
// it would narrow the content, which then wraps taller and decides anew
// whether the bar shows.
Flickable {
    id: scroller

    readonly property Item body: contentItem.children.length > 0 ? contentItem.children[0] : null

    implicitWidth: body ? body.implicitWidth : 0
    implicitHeight: body ? body.implicitHeight : 0
    contentWidth: width
    contentHeight: implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: AppScrollBar {
        parent: scroller.parent
        x: scroller.x + scroller.width + Math.max(0, (parent.rightPadding - width) / 2)
        y: scroller.y
        height: scroller.height
    }
}
