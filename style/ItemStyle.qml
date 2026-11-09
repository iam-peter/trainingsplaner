pragma Singleton
import QtQuick

// Entries of lists, menus and combo box lists: a row that lights up in
// the accent grey. Highlighted (the chosen row, the menu entry under the
// keyboard or pointer) is an override the item adds itself.
QtObject {
    id: root

    readonly property Semantics s: TokenInterface.semantics

    readonly property Style base: Style {
        background: TokenInterface.transparent
        text.color: root.s.text_default
        icon {
            color: root.s.text_default
            size: Primitives.size.s16
        }
        radius.value: Primitives.radius.r2
        padding.value: Primitives.spacing.sp100
        spacing: Primitives.spacing.sp100
        height: Primitives.size.s32
        opacity: 1

        Style {
            state: StyleState.Disable
            opacity: 0.5
        }
    }

    // ItemDelegate: also lights up under the pointer
    readonly property Style delegate: Style {
        width: 100

        Style {
            state: StyleState.Hover
            background: root.s.background_accent
        }
        Style {
            state: StyleState.Active
            background: root.s.background_accent
        }
    }

    // Menu entries: as wide as their text needs, at least 120 px; the
    // icon muted, the tick and the submenu arrow in the text colour
    readonly property Style menuItem: Style {
        width: 120
        icon.color: root.s.text_muted

        Style {
            state: StyleState.Active
            background: root.s.background_accent
        }
    }

    // The rows of a combo box's list, with room for the tick on the right
    readonly property Style comboItem: Style {
        padding.right: Primitives.spacing.sp100 + Primitives.size.s16 + Primitives.spacing.sp100
    }

    readonly property Style highlighted: Style {
        background: root.s.background_accent
    }
}
