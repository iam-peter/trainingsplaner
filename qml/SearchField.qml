import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A search field: a magnifier in front of the text and, as soon as there
// is text, a button behind it that clears it (Esc does the same).
TextField {
    id: field

    selectByMouse: true
    leadingIcon: Theme.icon("search")

    Keys.onEscapePressed: (event) => {
        if (text === "") {
            event.accepted = false
            return
        }
        clear()
        textEdited()
    }

    trailingItems: FieldButton {
        id: clearButton
        objectName: "clearButton"
        visible: field.text !== "" && !field.readOnly && field.enabled
        iconName: "x"
        toolTip: "Suche leeren"
        onClicked: {
            field.clear()
            field.textEdited()
            field.forceActiveFocus()
        }
    }
}
