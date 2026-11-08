import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

Page {
    id: page

    property string selectedId
    property bool dirty: false

    signal openWeekPlan(string athleteId)

    function select(id) {
        selectedId = id
        const a = Store.athletes.find(x => x.id === id)
        lastNameField.text = a ? a.lastName : ""
        firstNameField.text = a ? a.firstName : ""
        maleButton.checked = !a || a.sex === 0
        femaleButton.checked = a && a.sex === 1
        bornField.text = a ? a.born : ""
        phoneField.text = a ? a.phone : ""
        addressField.text = a ? a.address : ""
        dirty = false
        lastNameField.forceActiveFocus()
    }

    function save() {
        if (lastNameField.text.trim() === "") {
            lastNameField.forceActiveFocus()
            return
        }
        const id = Store.saveAthlete({
            id: selectedId,
            lastName: lastNameField.text,
            firstName: firstNameField.text,
            sex: femaleButton.checked ? 1 : 0,
            born: bornField.text,
            phone: phoneField.text,
            address: addressField.text
        })
        if (id !== "")
            select(id)
    }

    readonly property bool bornValid: bornField.text.trim() === "" || Store.parseDate(bornField.text) !== ""

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Frame {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            padding: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Label {
                    Layout.margins: 8
                    text: Store.athletes.length + " Sportler"
                    font.bold: true
                }
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Store.athletes
                    delegate: ItemDelegate {
                        required property var modelData
                        width: ListView.view.width
                        text: modelData.displayName
                        highlighted: modelData.id === page.selectedId
                        onClicked: page.select(modelData.id)
                    }
                    ScrollBar.vertical: ScrollBar {}
                }
                IconButton {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    iconName: "user-plus"
                    text: "Neuer Sportler"
                    onClicked: page.select("")
                }
            }
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                Label {
                    Layout.columnSpan: 2
                    text: page.selectedId === "" ? "Neuer Sportler" : "Sportler bearbeiten"
                    font.bold: true
                    font.pixelSize: 16
                }

                Label { text: "" }
                RowLayout {
                    RadioButton { id: maleButton; text: "Mann"; checked: true; onToggled: page.dirty = true }
                    RadioButton { id: femaleButton; text: "Frau"; onToggled: page.dirty = true }
                }

                Label { text: "Name:" }
                TextField {
                    id: lastNameField
                    Layout.preferredWidth: 300
                    onTextEdited: page.dirty = true
                }

                Label { text: "Vorname:" }
                TextField {
                    id: firstNameField
                    Layout.preferredWidth: 300
                    onTextEdited: page.dirty = true
                }

                Label { text: "geb.:" }
                RowLayout {
                    TextField {
                        id: bornField
                        Layout.preferredWidth: 120
                        placeholderText: "TT.MM.JJJJ"
                        onTextEdited: page.dirty = true
                        color: page.bornValid ? palette.text : "#c00000"
                    }
                    Label {
                        visible: !page.bornValid
                        text: "Datum ungültig"
                        color: "#c00000"
                    }
                }

                Label { text: "Telefon:"; Layout.alignment: Qt.AlignTop }
                TextArea {
                    id: phoneField
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 60
                    wrapMode: TextEdit.Wrap
                    onTextChanged: if (activeFocus) page.dirty = true
                }

                Label { text: "Adresse:"; Layout.alignment: Qt.AlignTop }
                TextArea {
                    id: addressField
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 80
                    wrapMode: TextEdit.Wrap
                    onTextChanged: if (activeFocus) page.dirty = true
                }

                Item { Layout.preferredHeight: 8; Layout.columnSpan: 2 }

                Item {}
                RowLayout {
                    spacing: 8
                    IconButton {
                        iconName: page.selectedId === "" ? "user-plus" : "save"
                        text: page.selectedId === "" ? "Hinzufügen" : "Speichern"
                        highlighted: true
                        enabled: lastNameField.text.trim() !== "" && page.bornValid
                                 && (page.dirty || page.selectedId === "")
                        onClicked: page.save()
                    }
                    IconButton {
                        iconName: "trash-2"
                        text: "Löschen"
                        enabled: page.selectedId !== ""
                        onClicked: {
                            deleteConfirm.sessions = Store.sessionCount(page.selectedId)
                            deleteConfirm.open()
                        }
                    }
                    IconButton {
                        iconName: "calendar-days"
                        text: "Wochenplan öffnen"
                        enabled: page.selectedId !== ""
                        onClicked: page.openWeekPlan(page.selectedId)
                    }
                }
            }
        }
    }

    Dialog {
        id: deleteConfirm
        property int sessions: 0
        title: "Sportler löschen?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: lastNameField.text + ", " + firstNameField.text + " wird gelöscht"
                  + (deleteConfirm.sessions > 0
                     ? ",\nzusammen mit " + deleteConfirm.sessions + " Trainingseinheiten." : ".")
                  + "\nDas kann nicht rückgängig gemacht werden."
        }
        onAccepted: {
            Store.removeAthlete(page.selectedId)
            page.select("")
        }
    }

    Component.onCompleted: {
        if (Store.athletes.length > 0)
            select(Store.athletes[0].id)
    }
}
