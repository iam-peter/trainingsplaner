import QtQuick
import QtQuick.Controls
import Trainingsplaner
import TrainingsplanerStyle as Styles

// A button inside a field (trailingItems): a calendar, a clock, clearing.
// Square, as high as the field less 2 px above and below, its icon at the
// normal 16 px; every padding is set, so nothing squeezes the icon.
IconToolButton {
    width: Styles.Primitives.size.s28
    height: Styles.Primitives.size.s28
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
}
