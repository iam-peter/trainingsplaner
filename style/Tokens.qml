pragma Singleton
import QtQuick

// The style's earlier names for sizes and colours, read from Primitives
// and TokenInterface; on its way out as the controls move to their
// styles.
QtObject {
    readonly property bool dark: TokenInterface.dark
    readonly property var s: TokenInterface.semantics

    // The "sm" size (h-8) suits a dense desktop program
    readonly property int controlHeight: Primitives.size.s32
    readonly property int radiusSm: Primitives.radius.r2
    readonly property int radiusMd: Primitives.radius.r4
    readonly property int radiusLg: Primitives.radius.r4
    readonly property int radiusXl: Primitives.radius.r4

    readonly property int space1: Primitives.spacing.sp050
    readonly property int space2: Primitives.spacing.sp100
    readonly property int space3: Primitives.spacing.sp150
    readonly property int space4: Primitives.spacing.sp200

    function alpha(c, a) {
        return Primitives.alpha(c, a)
    }

    readonly property color background: s.background_default
    readonly property color foreground: s.text_default
    readonly property color card: s.background_elevated
    readonly property color popover: s.background_elevated
    readonly property color primary: s.primary_default
    readonly property color primaryForeground: s.text_on_primary
    readonly property color secondary: s.background_secondary
    readonly property color secondaryForeground: s.text_default
    readonly property color muted: s.background_muted
    readonly property color mutedForeground: s.text_muted
    readonly property color accent: s.background_accent
    readonly property color accentForeground: s.text_default
    readonly property color destructive: s.danger_default
    readonly property color border: s.stroke_subtle
    readonly property color input: s.stroke_field
    readonly property color inputBackground: s.field_default
    readonly property color ring: s.stroke_focus
    readonly property color cell: s.cell_default
    readonly property color cellHover: s.cell_hover
    readonly property color cellBorder: s.cell_border
    readonly property color cellBorderHover: s.stroke_focus
    readonly property color outlineBackground: s.outline_default
    readonly property color outlineHover: s.outline_hover
    readonly property color outlineBorder: s.stroke_outline
    readonly property color ghostHover: s.background_hover
    readonly property color destructiveFill: s.danger_fill
    readonly property color fieldHover: s.field_hover
    readonly property color tabActive: s.field_default
    readonly property color tabActiveBorder: s.stroke_tab
    readonly property color tabInactiveText: s.text_inactive
    readonly property color switchThumb: s.switch_thumb
    readonly property color switchThumbChecked: s.switch_thumb_checked
    readonly property color scrollThumb: s.scroll_thumb
    readonly property color pickerChosen: s.picker_chosen
    readonly property color pickerHover: s.picker_hover
    readonly property real shadowStrength: s.shadow_strength
    readonly property var chart: s.chart_series
    readonly property color chartMuted: s.chart_muted
    readonly property color overlay: s.dim
}
