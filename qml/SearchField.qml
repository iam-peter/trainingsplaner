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

    trailingItems: IconToolButton {
        id: clearButton
        objectName: "clearButton"
        visible: field.text !== "" && !field.readOnly && field.enabled
        height: field.height - 4
        width: height
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        iconName: "x"
        toolTip: "Suche leeren"
        onClicked: {
            field.clear()
            field.textEdited()
            field.forceActiveFocus()
        }
    }
}
