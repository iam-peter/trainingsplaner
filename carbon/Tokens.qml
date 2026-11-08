pragma Singleton
import QtQuick

// Colour tokens of the IBM Carbon Design System (v11): the White theme in
// light mode and the Gray 100 theme in dark mode. Dark follows the
// program's colour scheme, like the rest of the program.
QtObject {
    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                 || system.window.hslLightness < 0.5

    // Sizes: the "small" control height suits a dense desktop program
    readonly property int controlHeight: 32
    readonly property int fieldHeight: 32
    readonly property int modalButtonHeight: 56

    readonly property color background: dark ? "#161616" : "#ffffff"
    readonly property color backgroundHover: dark ? "#292929" : "#e8e8e8"
    readonly property color layer01: dark ? "#262626" : "#f4f4f4"
    readonly property color layer02: dark ? "#393939" : "#ffffff"
    readonly property color layerHover: dark ? "#333333" : "#e8e8e8"
    readonly property color layerSelected: dark ? "#393939" : "#e0e0e0"
    readonly property color layerSelectedHover: dark ? "#474747" : "#d1d1d1"
    readonly property color layerActive: dark ? "#525252" : "#c6c6c6"
    readonly property color layerAccent: dark ? "#393939" : "#e0e0e0"
    readonly property color layerAccentHover: dark ? "#474747" : "#d1d1d1"
    readonly property color field: dark ? "#262626" : "#f4f4f4"
    readonly property color fieldHover: dark ? "#333333" : "#e8e8e8"
    readonly property color borderSubtle: dark ? "#393939" : "#e0e0e0"
    readonly property color borderStrong: dark ? "#6f6f6f" : "#8d8d8d"
    readonly property color borderInteractive: dark ? "#4589ff" : "#0f62fe"
    readonly property color borderDisabled: dark ? "#393939" : "#c6c6c6"

    readonly property color textPrimary: dark ? "#f4f4f4" : "#161616"
    readonly property color textSecondary: dark ? "#c6c6c6" : "#525252"
    readonly property color textPlaceholder: dark ? "#6f6f6f" : "#a8a8a8"
    readonly property color textHelper: dark ? "#a8a8a8" : "#6f6f6f"
    readonly property color textDisabled: dark ? Qt.rgba(0.957, 0.957, 0.957, 0.25) : Qt.rgba(0.086, 0.086, 0.086, 0.25)
    readonly property color textOnColor: "#ffffff"
    readonly property color textInverse: dark ? "#161616" : "#ffffff"
    readonly property color iconPrimary: textPrimary
    readonly property color iconSecondary: textSecondary
    readonly property color iconInverse: dark ? "#161616" : "#ffffff"

    readonly property color interactive: dark ? "#4589ff" : "#0f62fe"
    readonly property color link: dark ? "#78a9ff" : "#0f62fe"
    readonly property color focus: dark ? "#ffffff" : "#0f62fe"
    readonly property color focusInset: dark ? "#161616" : "#ffffff"
    readonly property color highlight: dark ? "#0043ce" : "#d0e2ff"

    readonly property color buttonPrimary: "#0f62fe"
    readonly property color buttonPrimaryHover: "#0050e6"
    readonly property color buttonPrimaryActive: "#002d9c"
    readonly property color buttonSecondary: dark ? "#6f6f6f" : "#393939"
    readonly property color buttonSecondaryHover: dark ? "#5e5e5e" : "#474747"
    readonly property color buttonSecondaryActive: dark ? "#393939" : "#6f6f6f"
    readonly property color buttonTertiary: dark ? "#ffffff" : "#0f62fe"
    readonly property color buttonTertiaryHover: dark ? "#f4f4f4" : "#0050e6"
    readonly property color buttonTertiaryActive: dark ? "#c6c6c6" : "#002d9c"
    readonly property color buttonDanger: "#da1e28"
    readonly property color buttonDangerHover: "#b81921"
    readonly property color buttonDisabled: dark ? "#525252" : "#c6c6c6"

    readonly property color supportError: dark ? "#fa4d56" : "#da1e28"
    readonly property color supportSuccess: dark ? "#42be65" : "#24a148"
    readonly property color backgroundInverse: dark ? "#f4f4f4" : "#393939"
    readonly property color toggleOff: dark ? "#6f6f6f" : "#8d8d8d"
    readonly property color overlay: dark ? Qt.rgba(0, 0, 0, 0.65) : Qt.rgba(0.086, 0.086, 0.086, 0.5)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.3)

    // Carbon's categorical data visualisation palette
    readonly property var chart: dark ? ["#8a3ffc", "#33b1ff", "#007d79", "#ff7eb6", "#fa4d56", "#6fdc8c"]
                                      : ["#6929c4", "#1192e8", "#005d5d", "#9f1853", "#fa4d56", "#198038"]
}
