pragma Singleton
import QtQuick
import QtQuick.Controls
import Trainingsplaner
import TrainingsplanerStyle as Style

// Colours and shapes of the program's own elements (the week grid, lists,
// tabs, highlights) for light and dark mode, from the style's tokens.
QtObject {
    readonly property var sh: Style.Tokens
    // The old program's colours, when chosen as colour scheme
    readonly property Binding classicColors: Binding {
        target: Style.TokenInterface
        property: "classic"
        value: Store.classicColors
    }
    // As the style decides it
    readonly property bool dark: sh.dark

    // Toolbars are as high on every page: a control and 6 px around it
    readonly property int toolBarHeight: sh.controlHeight + 12

    // Corner radius: at most 4 px
    function radius(r) {
        return Math.min(r, 4)
    }

    // List rows: the selection's gap to the list's border, the same on
    // every side (inset across, inset down plus the list's own margin)
    readonly property int rowInsetX: 4
    readonly property int rowInsetY: 2
    readonly property int listMargin: rowInsetX - rowInsetY

    // The palette for all controls
    readonly property color window: sh.background
    readonly property color windowText: sh.foreground
    readonly property color base: sh.card
    readonly property color alternateBase: sh.muted
    readonly property color text: sh.foreground
    readonly property color button: sh.secondary
    readonly property color buttonText: sh.foreground
    readonly property color placeholderText: sh.mutedForeground
    readonly property color mid: sh.border
    readonly property color darkShade: sh.ring
    readonly property color lightShade: sh.background
    readonly property color toolTipBase: sh.primary
    readonly property color toolTipText: sh.primaryForeground

    readonly property color cell: sh.cell
    readonly property color cellHover: sh.cellHover
    readonly property color cellBorder: sh.cellBorder
    readonly property color cellBorderHover: sh.cellBorderHover
    readonly property color cellText: sh.foreground
    readonly property color cellMuted: sh.mutedForeground
    readonly property color lineOutline: sh.ring
    readonly property color accent: sh.primary
    readonly property color selection: sh.primary
    readonly property color selectedText: sh.primaryForeground
    // List rows are selected quietly, in the accent grey
    readonly property color rowSelected: sh.accent
    readonly property color rowSelectedText: sh.accentForeground
    readonly property color error: sh.destructive
    // Borders of panels and lists, visible in every palette
    readonly property color line: sh.border
    readonly property color link: sh.foreground
    // Behind a modal dialog
    readonly property color dim: sh.overlay

    // Chart series: readable on the light and the dark chart background
    readonly property color ink: sh.chart[1]
    readonly property color slate: sh.chartMuted
    readonly property color blue: sh.chart[2]
    readonly property color green: sh.chart[3]
}
