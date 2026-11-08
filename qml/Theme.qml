pragma Singleton
import QtQuick
import QtQuick.Controls
import Trainingsplaner
import Carbon as Carbon

// Colours and shapes of the program's own elements (the week grid, lists,
// tabs, highlights) for light and dark mode and for the chosen style. With
// the Carbon style they come from Carbon's tokens; otherwise the palette
// follows the system or the chosen colour scheme.
QtObject {
    // Dark when the window colour is dark: works whether the system reports
    // a colour scheme or only sets a dark palette
    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                 || system.window.hslLightness < 0.5

    // The Qt Quick Controls style in use, chosen in the settings
    readonly property string style: Store.activeStyle
    readonly property bool carbon: style === "Carbon"
    readonly property var tokens: Carbon.Tokens

    // Toolbars are as high on every page; styles with taller fields
    // (Material) get taller toolbars
    readonly property ComboBox sizeProbe: ComboBox {}
    readonly property int toolBarHeight: Math.max(44, sizeProbe.implicitHeight + 10)

    // Corner radius: Carbon is square
    function radius(r) {
        return carbon ? 0 : r
    }

    // The palette for all controls
    readonly property color window: carbon ? tokens.background : system.window
    readonly property color windowText: carbon ? tokens.textPrimary : system.windowText
    readonly property color base: carbon ? tokens.layer01 : system.base
    readonly property color alternateBase: carbon ? tokens.layer02 : system.alternateBase
    readonly property color text: carbon ? tokens.textPrimary : system.text
    readonly property color button: carbon ? tokens.layer01 : system.button
    readonly property color buttonText: carbon ? tokens.textPrimary : system.buttonText
    readonly property color placeholderText: carbon ? tokens.textSecondary : system.placeholderText
    readonly property color mid: carbon ? tokens.borderSubtle : system.mid
    readonly property color darkShade: carbon ? tokens.borderStrong : system.dark
    readonly property color lightShade: carbon ? tokens.layer02 : system.light
    // SystemPalette has no tooltip colours
    readonly property color toolTipBase: carbon ? tokens.backgroundInverse : dark ? "#353331" : "#fffbeb"
    readonly property color toolTipText: carbon ? tokens.textInverse : system.windowText

    readonly property color cell: carbon ? tokens.layer01 : dark ? "#3a3220" : "#fff6cf"
    readonly property color cellHover: carbon ? tokens.layerHover : dark ? "#4a3f24" : "#fff0b0"
    readonly property color cellBorder: carbon ? tokens.borderSubtle : dark ? "#6b5a2e" : "#8c7a45"
    readonly property color cellBorderHover: carbon ? tokens.borderStrong : dark ? "#d4a72c" : "#b08a00"
    readonly property color cellText: carbon ? tokens.textPrimary : dark ? "#f2ece0" : "#1c1917"
    readonly property color cellMuted: carbon ? tokens.textHelper : dark ? "#b3a27a" : "#9a8a5a"
    readonly property color lineOutline: carbon ? tokens.interactive : dark ? "#f87171" : "#c81e1e"
    readonly property color accent: carbon ? tokens.interactive : dark ? "#fb923c" : "#c2410c"
    // Selections in every scheme, also when following the system, so they
    // match the tabs and the rest of the program
    readonly property color selection: carbon ? tokens.highlight : "#c2410c"
    readonly property color selectedText: carbon ? tokens.textPrimary : "#ffffff"
    readonly property color error: carbon ? tokens.supportError : dark ? "#f87171" : "#c00000"
    // Borders of panels and lists, visible in every palette
    readonly property color line: carbon ? tokens.borderSubtle
                                         : Qt.rgba(system.windowText.r, system.windowText.g, system.windowText.b, 0.22)
    readonly property color link: carbon ? tokens.link : dark ? "#93c5fd" : "#1d4ed8"
    // Behind a modal dialog
    readonly property color dim: carbon ? tokens.overlay : Qt.rgba(0, 0, 0, 0.45)

    // Chart series: readable on the light and the dark chart background
    readonly property color ink: carbon ? tokens.chart[0] : dark ? "#d6d3d1" : "#44403c"
    readonly property color slate: carbon ? tokens.chart[2] : dark ? "#94a3b8" : "#64748b"
    readonly property color blue: carbon ? tokens.chart[1] : dark ? "#60a5fa" : "#2563eb"
    readonly property color green: carbon ? tokens.chart[5] : dark ? "#4ade80" : "#16a34a"
}
