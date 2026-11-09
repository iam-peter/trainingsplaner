pragma Singleton
import QtQuick

// The colour roles of the scheme in use: light, dark or the old
// program's. Each scheme maps every role of Semantics to a Primitive; the
// control styles and the program's pages only use `semantics`.
QtObject {
    id: root

    readonly property SystemPalette system: SystemPalette {}
    readonly property bool dark: !classic && (Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
                                              || system.window.hslLightness < 0.5)

    // The old program's colours; light only. The program sets it with its
    // colour scheme.
    property bool classic: false

    readonly property color transparent: "#00000000"

    readonly property Semantics semantics: classic ? root.classicScheme : dark ? root.darkScheme : root.lightScheme

    // Text and background have about the same contrast in light and dark
    // (13.5:1, against 19:1 for pure black and white), so neither is
    // harsh; grey text keeps at least 4.5:1.
    readonly property Semantics lightScheme: Semantics {
        readonly property var n: Primitives.neutrals
        readonly property var a: Primitives.accents

        text_default: n.neutral_165
        text_muted: n.neutral_431
        text_inactive: n.neutral_165
        text_on_primary: n.neutral_980
        text_on_danger: n.neutral_1000

        primary_default: n.neutral_165
        danger_default: a.red_453
        danger_fill: a.red_453

        background_default: n.neutral_973
        background_elevated: n.neutral_1000
        background_muted: n.neutral_933
        background_secondary: n.neutral_933
        background_accent: n.neutral_933
        background_hover: n.neutral_933

        field_default: n.neutral_1000
        field_hover: n.neutral_1000

        outline_default: n.neutral_973
        outline_hover: n.neutral_933

        stroke_subtle: n.neutral_878
        stroke_field: n.neutral_855
        stroke_focus: n.neutral_451
        stroke_outline: n.neutral_878
        stroke_tab: root.transparent

        switch_thumb: n.neutral_973
        switch_thumb_checked: n.neutral_973
        scroll_thumb: n.neutral_831

        picker_chosen: n.neutral_894
        picker_hover: n.neutral_941

        cell_default: n.neutral_1000
        cell_hover: n.neutral_933
        cell_border: n.neutral_878

        chart_series: [a.orange_480, a.teal_294, a.pine_227, a.yellow_500, a.amber_498]
        chart_muted: n.neutral_831

        dim: Primitives.alpha(n.neutral_000, 0.5)
        shadow_strength: 0.06
    }

    readonly property Semantics darkScheme: Semantics {
        readonly property var n: Primitives.neutrals
        readonly property var a: Primitives.accents

        text_default: n.neutral_902
        text_muted: n.neutral_627
        text_inactive: n.neutral_627
        text_on_primary: n.neutral_118
        text_on_danger: n.neutral_1000

        primary_default: n.neutral_878
        danger_default: a.red_631
        danger_fill: Primitives.alpha(a.red_631, 0.6)

        background_default: n.neutral_118
        background_elevated: n.neutral_149
        background_muted: n.neutral_180
        background_secondary: n.neutral_196
        background_accent: n.neutral_200
        background_hover: n.neutral_165

        field_default: n.neutral_141
        field_hover: n.neutral_173

        outline_default: n.neutral_141
        outline_hover: n.neutral_173

        stroke_subtle: n.neutral_227
        stroke_field: n.neutral_271
        stroke_focus: n.neutral_604
        stroke_outline: n.neutral_271
        stroke_tab: n.neutral_271

        switch_thumb: n.neutral_902
        switch_thumb_checked: n.neutral_118
        scroll_thumb: Primitives.alpha(n.neutral_1000, 0.25)

        picker_chosen: n.neutral_227
        picker_hover: n.neutral_180

        cell_default: n.neutral_149
        cell_hover: n.neutral_200
        cell_border: n.neutral_227

        chart_series: [a.cobalt_490, a.green_369, a.amber_498, a.violet_637, a.rose_563]
        chart_muted: n.neutral_322

        dim: Primitives.alpha(n.neutral_000, 0.5)
        shadow_strength: 0.3
    }

    // The old program under Windows XP: beige window, white fields with
    // blue-grey borders, blue selections, yellow boxes with black borders
    readonly property Semantics classicScheme: Semantics {
        readonly property var n: Primitives.neutrals
        readonly property var a: Primitives.accents

        text_default: n.neutral_000
        text_muted: a.beige_418
        text_inactive: n.neutral_000
        text_on_primary: n.neutral_1000
        text_on_danger: n.neutral_1000

        primary_default: a.blue_482
        danger_default: a.red_439
        danger_fill: a.red_439

        background_default: a.beige_886
        background_elevated: n.neutral_1000
        background_muted: a.beige_953
        background_secondary: n.neutral_969
        background_accent: a.blue_845
        background_hover: a.blue_845

        field_default: n.neutral_1000
        field_hover: n.neutral_1000

        outline_default: n.neutral_969
        outline_hover: a.blue_935

        stroke_subtle: a.beige_637
        stroke_field: a.steel_612
        stroke_focus: a.blue_482
        stroke_outline: a.navy_225
        stroke_tab: root.transparent

        switch_thumb: n.neutral_1000
        switch_thumb_checked: n.neutral_1000
        scroll_thumb: a.blue_845

        picker_chosen: a.blue_845
        picker_hover: a.blue_935

        cell_default: a.yellow_869
        cell_hover: a.yellow_814
        cell_border: n.neutral_000

        chart_series: [a.orange_480, a.teal_294, a.pine_227, a.yellow_500, a.amber_498]
        chart_muted: a.beige_637

        dim: Primitives.alpha(n.neutral_000, 0.5)
        shadow_strength: 0.06
    }
}
