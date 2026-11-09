pragma Singleton
import QtQuick

// The style's design tokens: sizes, spacing and the colours of the scheme
// in use (light, dark or the old program's), following the program's
// colour scheme like the rest of the program. The neutral greys started
// from shadcn/ui 4.
QtObject {
    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: !classic && (Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                              || system.window.hslLightness < 0.5)

    // The old program's colours; light only. The program sets it with its
    // colour scheme.
    property bool classic: false

    // The "sm" size (h-8) suits a dense desktop program
    readonly property int controlHeight: 32
    // Corner radii, kept small: never more than 4 px; small items inside a
    // rounded container get 2 px
    readonly property int radiusSm: 2
    readonly property int radiusMd: 4
    readonly property int radiusLg: 4
    readonly property int radiusXl: 4

    // Spacing in steps of 4: gaps and item padding 8, control padding 12,
    // dialog and card padding 16, tight insets 4
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    // The three schemes. Text and background have about the same contrast
    // in light and dark (13.5:1, against 19:1 for pure black and white),
    // so neither is harsh; grey text keeps at least 4.5:1.
    readonly property SchemeColors lightPalette: SchemeColors {
        background: "#f8f8f8"
        foreground: "#2a2a2a"
        card: "#ffffff"
        popover: "#ffffff"
        primary: "#2a2a2a"
        primaryForeground: "#fafafa"
        secondary: "#eeeeee"
        secondaryForeground: "#2a2a2a"
        muted: "#eeeeee"
        mutedForeground: "#6e6e6e"
        accent: "#eeeeee"
        accentForeground: "#2a2a2a"
        destructive: "#e7000b"
        border: "#e0e0e0"
        input: "#dadada"
        inputBackground: "#ffffff"
        inputHover: "#eeeeee"
        ring: "#737373"
        cell: "#ffffff"
        cellHover: "#eeeeee"
        cellBorder: "#e0e0e0"
        cellBorderHover: "#737373"
        outlineBackground: "#f8f8f8"
        outlineHover: "#eeeeee"
        outlineBorder: "#e0e0e0"
        ghostHover: "#eeeeee"
        destructiveFill: "#e7000b"
        fieldHover: "#ffffff"
        tabActive: "#ffffff"
        tabActiveBorder: "transparent"
        tabInactiveText: "#2a2a2a"
        switchThumb: "#f8f8f8"
        switchThumbChecked: "#f8f8f8"
        scrollThumb: "#d4d4d4"
        chartMuted: "#d4d4d4"
        pickerChosen: "#e4e4e4"
        pickerHover: "#f0f0f0"
        shadowStrength: 0.06
        chart: ["#f54a00", "#009689", "#104e64", "#ffb900", "#fe9a00"]
    }
    readonly property SchemeColors darkPalette: SchemeColors {
        background: "#1e1e1e"
        foreground: "#e6e6e6"
        card: "#262626"
        popover: "#262626"
        primary: "#e0e0e0"
        primaryForeground: "#1e1e1e"
        secondary: "#323232"
        secondaryForeground: "#e6e6e6"
        muted: "#2e2e2e"
        mutedForeground: "#a0a0a0"
        accent: "#333333"
        accentForeground: "#e6e6e6"
        destructive: "#f05252"
        border: "#3a3a3a"
        input: "#454545"
        inputBackground: "#242424"
        inputHover: "#2c2c2c"
        ring: "#9a9a9a"
        cell: "#262626"
        cellHover: "#333333"
        cellBorder: "#3a3a3a"
        cellBorderHover: "#9a9a9a"
        outlineBackground: "#242424"
        outlineHover: "#2c2c2c"
        outlineBorder: "#454545"
        ghostHover: "#2a2a2a"
        destructiveFill: "#99f05252"
        fieldHover: "#2c2c2c"
        tabActive: "#242424"
        tabActiveBorder: "#454545"
        tabInactiveText: "#a0a0a0"
        switchThumb: "#e6e6e6"
        switchThumbChecked: "#1e1e1e"
        scrollThumb: "#40ffffff"
        chartMuted: "#525252"
        pickerChosen: "#3a3a3a"
        pickerHover: "#2e2e2e"
        shadowStrength: 0.3
        chart: ["#1447e6", "#00bc7d", "#fe9a00", "#ad46ff", "#ff2056"]
    }
    // The old program under Windows XP: beige window, white fields with
    // blue-grey borders, blue selections, yellow boxes with black borders
    readonly property SchemeColors classicPalette: SchemeColors {
        background: "#ece9d8"
        foreground: "#000000"
        card: "#ffffff"
        popover: "#ffffff"
        primary: "#316ac5"
        primaryForeground: "#ffffff"
        secondary: "#f7f7f7"
        secondaryForeground: "#000000"
        muted: "#f7f3ef"
        mutedForeground: "#716f64"
        accent: "#c1d2ee"
        accentForeground: "#000000"
        destructive: "#c42b1c"
        border: "#aca899"
        input: "#7f9db9"
        inputBackground: "#ffffff"
        inputHover: "#e3ecfa"
        ring: "#316ac5"
        cell: "#fff4bc"
        cellHover: "#ffeda0"
        cellBorder: "#000000"
        cellBorderHover: "#316ac5"
        outlineBackground: "#f7f7f7"
        outlineHover: "#e3ecfa"
        outlineBorder: "#003c73"
        ghostHover: "#c1d2ee"
        destructiveFill: "#c42b1c"
        fieldHover: "#ffffff"
        tabActive: "#ffffff"
        tabActiveBorder: "transparent"
        tabInactiveText: "#000000"
        switchThumb: "#ffffff"
        switchThumbChecked: "#ffffff"
        scrollThumb: "#c1d2ee"
        chartMuted: "#aca899"
        pickerChosen: "#c1d2ee"
        pickerHover: "#e3ecfa"
        shadowStrength: 0.06
        chart: ["#f54a00", "#009689", "#104e64", "#ffb900", "#fe9a00"]
    }

    // The scheme in use, decided once; every colour below follows it
    readonly property SchemeColors current: classic ? classicPalette : dark ? darkPalette : lightPalette

    readonly property color background: current.background
    readonly property color foreground: current.foreground
    readonly property color card: current.card
    readonly property color popover: current.popover
    readonly property color primary: current.primary
    readonly property color primaryForeground: current.primaryForeground
    readonly property color secondary: current.secondary
    readonly property color secondaryForeground: current.secondaryForeground
    readonly property color muted: current.muted
    readonly property color mutedForeground: current.mutedForeground
    readonly property color accent: current.accent
    readonly property color accentForeground: current.accentForeground
    readonly property color destructive: current.destructive
    readonly property color border: current.border
    readonly property color input: current.input
    readonly property color inputBackground: current.inputBackground
    readonly property color inputHover: current.inputHover
    readonly property color ring: current.ring
    readonly property color cell: current.cell
    readonly property color cellHover: current.cellHover
    readonly property color cellBorder: current.cellBorder
    readonly property color cellBorderHover: current.cellBorderHover
    readonly property color outlineBackground: current.outlineBackground
    readonly property color outlineHover: current.outlineHover
    readonly property color outlineBorder: current.outlineBorder
    readonly property color ghostHover: current.ghostHover
    readonly property color destructiveFill: current.destructiveFill
    readonly property color fieldHover: current.fieldHover
    readonly property color tabActive: current.tabActive
    readonly property color tabActiveBorder: current.tabActiveBorder
    readonly property color tabInactiveText: current.tabInactiveText
    readonly property color switchThumb: current.switchThumb
    readonly property color switchThumbChecked: current.switchThumbChecked
    readonly property color scrollThumb: current.scrollThumb
    readonly property color pickerChosen: current.pickerChosen
    readonly property color pickerHover: current.pickerHover
    readonly property real shadowStrength: current.shadowStrength
    readonly property var chart: current.chart
    readonly property color chartMuted: current.chartMuted
    readonly property color overlay: Qt.rgba(0, 0, 0, 0.5)
}
