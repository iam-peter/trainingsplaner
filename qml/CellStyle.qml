pragma Singleton
import QtQuick
import TrainingsplanerStyle

// The week's session boxes: a box with a border that thickens under the
// pointer, for today and with the keyboard focus. Its parts: the session
// number (Label), the plus of an empty box (Icon) and the outline of the
// exercise line under the pointer (Indicator).
QtObject {
    id: root

    readonly property Semantics s: TokenInterface.semantics

    readonly property Style base: Style {
        background: root.s.cell_default
        border {
            width: Primitives.stroke.thin
            color: root.s.cell_border
        }
        radius.value: Primitives.radius.r4
        text.color: root.s.text_default

        Style {
            state: StyleState.Hover
            background: root.s.cell_hover
            border {
                width: Primitives.stroke.thick
                color: root.s.stroke_focus
            }
        }
        Style {
            part: StylePart.Label
            text.color: root.s.text_muted
        }
        Style {
            part: StylePart.Icon
            icon.color: root.s.stroke_focus
        }
        Style {
            part: StylePart.Indicator
            border {
                width: Primitives.stroke.thick
                color: root.s.stroke_focus
            }
        }
    }

    // Today's box is framed in the accent, but the pointer's frame wins
    readonly property Style today: Style {
        border {
            width: Primitives.stroke.thick
            color: root.s.primary_default
        }

        Style {
            state: StyleState.Hover
            border.color: root.s.stroke_focus
        }
    }

    // The session the panel beside the week edits: tinted and framed
    readonly property Style selected: Style {
        background: root.s.background_accent
        border {
            width: Primitives.stroke.thick
            color: root.s.primary_default
        }
    }

    readonly property Style focus: Style {
        border {
            width: Primitives.stroke.thick
            color: root.s.primary_default
        }
    }
}
