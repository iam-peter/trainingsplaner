import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Controls.impl
import Trainingsplaner

// A search field: a magnifier in front of the text and, as soon as there
// is text, a button behind it that clears it (Esc does the same).
TextField {
    id: field

    selectByMouse: true
    leftPadding: searchIcon.x + searchIcon.width + 6
    rightPadding: clearButton.visible ? clearButton.width + 4 : 12

    Keys.onEscapePressed: (event) => {
        if (text === "") {
            event.accepted = false
            return
        }
        clear()
        textEdited()
    }

    IconImage {
        id: searchIcon
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        source: "qrc:/qt/qml/Trainingsplaner/icons/search.svg"
        color: Styles.TokenInterface.semantics.text_muted
    }

    IconToolButton {
        id: clearButton
        objectName: "clearButton"
        visible: field.text !== "" && !field.readOnly && field.enabled
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 4
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
