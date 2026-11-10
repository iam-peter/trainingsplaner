pragma Singleton
import QtQuick
import TrainingsplanerStyle as Styles

// What the program's own elements share beyond colours and the style's
// values: icons, the width of form fields and the insets of list rows.
// Colours come from Styles.TokenInterface.semantics, sizes from
// Styles.Primitives, styles of controls from the style's *Style
// singletons.
QtObject {
    // Toolbars are as high on every page: a control and 6 px around it
    readonly property int toolBarHeight: Styles.Primitives.size.s32 + 2 * Styles.Primitives.spacing.sp075

    // A Lucide icon of the program (icons/<name>.svg); none for ""
    function icon(name: string): url {
        return name !== "" ? "qrc:/qt/qml/Trainingsplaner/icons/" + name + ".svg" : ""
    }

    // Fields of forms grow with the window up to this width, which keeps
    // a line readable
    readonly property int fieldWidth: 420

    // List rows: the selection's gap to the list's border, the same on
    // every side (inset across, inset down plus the list's own margin)
    readonly property int rowInsetX: 4
    readonly property int rowInsetY: 2
    readonly property int listMargin: rowInsetX - rowInsetY
}
