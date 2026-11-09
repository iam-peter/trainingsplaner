pragma Singleton
import QtQuick

// The style's design tokens, from the "neutral" colours of shadcn/ui 4 (the
// oklch values as sRGB), light and dark, following the program's colour
// scheme like the rest of the program.
QtObject {
    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: !classic && (Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                              || system.window.hslLightness < 0.5)

    // The old program's colours (Windows XP): beige window, white fields
    // with blue-grey borders, blue selections, yellow session boxes. Light
    // only; the program sets it with its colour scheme.
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

    readonly property color background: classic ? "#ece9d8" : dark ? "#0a0a0a" : "#ffffff"
    readonly property color foreground: classic ? "#000000" : dark ? "#fafafa" : "#0a0a0a"
    readonly property color card: classic ? "#ffffff" : dark ? "#171717" : "#ffffff"
    readonly property color popover: classic ? "#ffffff" : dark ? "#171717" : "#ffffff"
    readonly property color primary: classic ? "#316ac5" : dark ? "#e5e5e5" : "#171717"
    readonly property color primaryForeground: classic ? "#ffffff" : dark ? "#171717" : "#fafafa"
    readonly property color secondary: classic ? "#f7f7f7" : dark ? "#262626" : "#f5f5f5"
    readonly property color secondaryForeground: classic ? "#000000" : dark ? "#fafafa" : "#171717"
    readonly property color muted: classic ? "#f7f3ef" : dark ? "#262626" : "#f5f5f5"
    readonly property color mutedForeground: classic ? "#716f64" : dark ? "#a1a1a1" : "#737373"
    readonly property color accent: classic ? "#c1d2ee" : dark ? "#262626" : "#f5f5f5"
    readonly property color accentForeground: classic ? "#000000" : dark ? "#fafafa" : "#171717"
    readonly property color destructive: classic ? "#c42b1c" : dark ? "#ff6467" : "#e7000b"
    readonly property color border: classic ? "#aca899" : dark ? Qt.rgba(1, 1, 1, 0.10) : "#e5e5e5"
    readonly property color input: classic ? "#7f9db9" : dark ? Qt.rgba(1, 1, 1, 0.15) : "#e5e5e5"
    // bg-transparent, dark:bg-input/30 on the page background, as solid
    // colours: the soft shadow behind a control would show through
    readonly property color inputBackground: classic ? "#ffffff" : dark ? "#141414" : "#ffffff"
    readonly property color inputHover: classic ? "#e3ecfa" : dark ? "#1c1c1c" : accent
    // The focus border; a step stronger than shadcn/ui's ring, which was made
    // for a glow around it and is too faint as a border alone
    readonly property color ring: classic ? "#316ac5" : dark ? "#a1a1a1" : "#737373"
    // The week's session boxes: like cards, in the classic colours the old
    // program's yellow boxes with black borders
    readonly property color cell: classic ? "#fff4bc" : card
    readonly property color cellHover: classic ? "#ffeda0" : accent
    readonly property color cellBorder: classic ? "#000000" : border
    readonly property color cellBorderHover: classic ? "#316ac5" : ring
    readonly property color overlay: Qt.rgba(0, 0, 0, 0.5)
    readonly property real shadowStrength: dark ? 0.35 : 0.06

    readonly property var chart: dark ? ["#1447e6", "#00bc7d", "#fe9a00", "#ad46ff", "#ff2056"]
                                      : ["#f54a00", "#009689", "#104e64", "#ffb900", "#fe9a00"]
}
