pragma Singleton
import QtQuick

// Colours of the app's own elements (the week grid, highlights) for light
// and dark mode. Everything else follows the system palette.
QtObject {
    // Dark when the window colour is dark: works whether the system reports
    // a colour scheme or only sets a dark palette
    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                 || system.window.hslLightness < 0.5

    readonly property color cell: dark ? "#3a3220" : "#fff6cf"
    readonly property color cellHover: dark ? "#4a3f24" : "#fff0b0"
    readonly property color cellBorder: dark ? "#6b5a2e" : "#8c7a45"
    readonly property color cellBorderHover: dark ? "#d4a72c" : "#b08a00"
    readonly property color cellText: dark ? "#f2ece0" : "#1c1917"
    readonly property color cellMuted: dark ? "#b3a27a" : "#9a8a5a"
    readonly property color lineOutline: dark ? "#f87171" : "#c81e1e"
    readonly property color accent: dark ? "#fb923c" : "#c2410c"
    readonly property color error: dark ? "#f87171" : "#c00000"
    // Borders of panels and lists, visible in every palette
    readonly property color line: Qt.rgba(system.windowText.r, system.windowText.g, system.windowText.b, 0.22)
    readonly property color link: dark ? "#93c5fd" : "#1d4ed8"

    // Chart series: readable on the light and the dark chart background
    readonly property color ink: dark ? "#d6d3d1" : "#44403c"
    readonly property color slate: dark ? "#94a3b8" : "#64748b"
    readonly property color blue: dark ? "#60a5fa" : "#2563eb"
    readonly property color green: dark ? "#4ade80" : "#16a34a"
}
