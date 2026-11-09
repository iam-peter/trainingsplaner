import QtQuick

// The colours of one colour scheme; Tokens holds one per scheme and
// passes on the one in use.
QtObject {
    property color background
    property color foreground
    property color card
    property color popover
    property color primary
    property color primaryForeground
    property color secondary
    property color secondaryForeground
    property color muted
    property color mutedForeground
    property color accent
    property color accentForeground
    property color destructive
    property color border
    property color input
    // Fields and outlined buttons
    property color inputBackground
    property color inputHover
    // The focus border
    property color ring
    // The week's session boxes
    property color cell
    property color cellHover
    property color cellBorder
    property color cellBorderHover
    // What the controls make of those, where the schemes differ
    property color outlineBackground   // an outlined button at rest
    property color outlineHover
    property color outlineBorder
    property color ghostHover          // a flat button under the pointer
    property color destructiveFill
    property color fieldHover          // a combo box under the pointer
    property color tabActive
    property color tabActiveBorder
    property color tabInactiveText
    property color switchThumb
    property color switchThumbChecked
    property color scrollThumb
    // The pickers (date, week, time): the chosen entry and the one under
    // the pointer
    property color pickerChosen
    property color pickerHover
    property real shadowStrength
    property var chart
    property color chartMuted
}
