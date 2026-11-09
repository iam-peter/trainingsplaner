pragma Singleton
import QtQuick

// Fields: text fields, text areas, spin boxes and combo boxes. base is the
// bordered input every field shares; the field's own style adds its
// sizes, and what it forces itself (focus, read only) comes last.
QtObject {
    id: root

    readonly property Semantics s: TokenInterface.semantics

    readonly property Style base: Style {
        background: root.s.field_default
        border {
            width: Primitives.stroke.thin
            color: root.s.stroke_field
        }
        radius.value: Primitives.radius.r4
        height: Primitives.size.s32
        width: Primitives.size.s160
        text.color: root.s.text_default
        placeholder: root.s.text_muted
        selection: root.s.primary_default
        selectedText: root.s.text_on_primary
        opacity: 1

        Style {
            state: StyleState.Disable
            opacity: 0.5
        }
    }

    readonly property Style textField: Style {
        padding {
            horizontal: Primitives.spacing.sp150
            vertical: Primitives.spacing.sp050
        }
    }

    readonly property Style textArea: Style {
        width: 200
        padding {
            horizontal: Primitives.spacing.sp150
            vertical: Primitives.spacing.sp100
        }
    }

    // The steps are buttons inside the field: a part each, with its own
    // state; the sign greys out at the end of the range
    readonly property Style spinBox: Style {
        width: 120
        padding.left: Primitives.spacing.sp150

        Style {
            part: StylePart.Indicator
            background: TokenInterface.transparent
            radius.value: Primitives.radius.r2
            width: Primitives.size.s24
            text.color: root.s.text_default

            Style {
                state: StyleState.Hover
                background: root.s.background_accent
            }
            Style {
                state: StyleState.Active
                background: root.s.background_accent
            }
            Style {
                state: StyleState.Disable
                text.color: root.s.text_muted
            }
        }
    }

    // A trigger with a faint chevron; lighter under the pointer
    readonly property Style comboBox: Style {
        padding {
            horizontal: Primitives.spacing.sp150
            vertical: Primitives.spacing.sp050
        }
        spacing: Primitives.spacing.sp100

        Style {
            state: StyleState.Hover
            background: root.s.field_hover
        }
        Style {
            part: StylePart.Arrow
            icon {
                color: root.s.text_muted
                size: Primitives.size.s16
            }
            opacity: 0.8
        }
    }

    // What a field forces itself
    readonly property Style focus: Style {
        border.color: root.s.stroke_focus
    }
    readonly property Style readOnly: Style {
        background: TokenInterface.transparent
    }
    // Narrow fields (a number of reps) keep room for their text
    readonly property Style narrow: Style {
        padding.horizontal: Primitives.spacing.sp050
    }
    // An editable combo box: the text field inside has the padding
    readonly property Style editable: Style {
        padding.left: 0
    }
}
