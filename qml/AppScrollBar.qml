import QtQuick
import QtQuick.Controls

// A scroll bar that stays visible while there is more than fits, so a
// list cut off at a row's edge still shows that it goes on. The styles'
// own bars show only while scrolling.
ScrollBar {
    policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
    // The room rows leave on the side for the bar, 0 while it is hidden
    readonly property real room: policy === ScrollBar.AlwaysOn ? width + 4 : 0
}
