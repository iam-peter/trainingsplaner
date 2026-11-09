import QtQuick
import QtQuick.Controls

// A scroll bar that stays visible while there is more than fits, so a
// list cut off at a row's edge still shows that it goes on. The styles'
// own bars show only while scrolling. With nothing to scroll it is off:
// a hidden bar still took the presses beside it in some styles
// (Material), which made the right half of the rows' delete buttons dead.
ScrollBar {
    policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    // The room rows leave on the side for the bar, 0 while it is off
    readonly property real room: policy === ScrollBar.AlwaysOn ? width + 4 : 0
}
