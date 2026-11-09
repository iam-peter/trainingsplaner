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
        const attrs = a ? a.attributes : ({})
        for (let i = 0; i < attributeRepeater.count; ++i) {
            const item = attributeRepeater.itemAt(i)
            item.value = attrs[item.art] || ""
        }
        ageLabel.text = a && a.age >= 0 ? a.age + " Jahre" : ""
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
        if (id !== "") {
            const values = {}
            for (let i = 0; i < attributeRepeater.count; ++i) {
                const item = attributeRepeater.itemAt(i)
                values[item.art] = item.value
            }
            Store.setAthleteAttributes(id, values)
            select(id)
        }
    }

    Shortcut {
        sequences: [StandardKey.Save]
        enabled: page.visible && page.dirty && DialogStack.open === 0
        onActivated: page.save()
    }

    // The athletes matching the search field
    readonly property var shown: {
        const q = searchField.text.trim().toLowerCase()
        return q === "" ? Store.athletes : Store.athletes.filter(a => a.displayName.toLowerCase().indexOf(q) >= 0)
    }

    function askRemove(id) {
        const a = Store.athletes.find(x => x.id === id)
        if (!a)
            return
        deleteConfirm.athleteId = id
        deleteConfirm.name = a.displayName
        deleteConfirm.sessions = Store.sessionCount(id)
        deleteConfirm.open()
    }

    readonly property bool bornValid: bornField.text.trim() === "" || Store.parseDate(bornField.text) !== ""

    // Like every page, so switching pages does not shift the content
    header: AppToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            TextField {
                id: searchField
                objectName: "searchField"
                Layout.preferredWidth: 220
                placeholderText: "Sportler suchen"
                selectByMouse: true
            }
            Label {
                Layout.leftMargin: 8
                text: page.shown.length === Store.athletes.length
                      ? (Store.athletes.length === 1 ? "1 Sportler" : Store.athletes.length + " Sportler")
                      : page.shown.length + " von " + Store.athletes.length + " Sportlern"
                color: palette.placeholderText
            }
            Item { Layout.fillWidth: true }
        }
    }

    RowLayout {
        anchors.fill: parent
        // Lined up with the toolbar above (8 px from the window edge)
        anchors.margins: 8
        spacing: 12

        Panel {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            // Rows stay inside the border
            padding: 1
            filled: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // With the rows' inset, the selection keeps the same gap to the
                    // border on every side
                    topMargin: Theme.listMargin
                    bottomMargin: Theme.listMargin
                    model: page.shown
                    delegate: ListRow {
                        required property var modelData
                        text: modelData.displayName
                        highlighted: modelData.id === page.selectedId
                        deleteToolTip: "Sportler löschen"
                        onClicked: page.select(modelData.id)
                        onDeleteRequested: page.askRemove(modelData.id)
                    }
                    ScrollBar.vertical: AppScrollBar {}
                    Label {
                        anchors.centerIn: parent
                        visible: page.shown.length === 0
                        text: Store.athletes.length === 0 ? "Noch keine Sportler." : "Niemand gefunden."
                        color: palette.placeholderText
                    }
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

        Panel {
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
                    spacing: 8
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
                    spacing: 8
                    DateField {
                        id: bornField
                        Layout.preferredWidth: 136
                        onTextEdited: page.dirty = true
                        color: page.bornValid ? palette.text : Theme.error
                    }
                    Label {
                        visible: !page.bornValid
                        text: "Datum ungültig"
                        color: Theme.error
                    }
                    Label {
                        id: ageLabel
                        visible: page.bornValid
                        color: palette.placeholderText
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

                Label { text: "Zugehörigkeit:"; Layout.alignment: Qt.AlignTop; Layout.topMargin: 8 }
                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 4
                    Repeater {
                        id: attributeRepeater
                        model: Store.attributeNames
                        ColumnLayout {
                            id: attribute
                            required property string modelData
                            readonly property string art: modelData
                            property string value
                            spacing: 0
                            Label { text: attribute.art + ":"; font.pixelSize: 11; color: palette.placeholderText }
                            RowLayout {
                                spacing: 4
                                ComboBox {
                                    objectName: "attr_" + attribute.art
                                    implicitWidth: 200
                                    editable: true
                                    model: Store.attributeValues(attribute.art)
                                    editText: attribute.value
                                    onEditTextChanged: {
                                        if (editText !== attribute.value) {
                                            attribute.value = editText
                                            page.dirty = true
                                        }
                                    }
                                }
                                IconToolButton {
                                    // As in the old program: edit the values
                                    // with their time ranges
                                    iconName: "square-pen"
                                    toolTip: "Erfassung " + attribute.art + " (mit Zeiträumen)"
                                    enabled: page.selectedId !== ""
                                    onClicked: historyDialog.edit(page.selectedId, attribute.art)
                                }
                            }
                        }
                    }
                }
                Label {
                    Layout.columnSpan: 2
                    font.pixelSize: 11
                    color: palette.placeholderText
                    text: "Geänderte Zugehörigkeiten gelten ab heute; der Verlauf bleibt erhalten."
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
                        iconName: "calendar-days"
                        text: "Wochenplan öffnen"
                        enabled: page.selectedId !== ""
                        onClicked: page.openWeekPlan(page.selectedId)
                    }
                }
            }
        }
    }

    AttributeHistoryDialog {
        id: historyDialog
        onChanged: page.select(page.selectedId)
    }

    AppDialog {
        id: deleteConfirm
        property string athleteId
        property string name
        property int sessions: 0
        title: "Sportler löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: deleteConfirm.name + " wird gelöscht"
                  + (deleteConfirm.sessions > 0
                     ? ",\nzusammen mit " + deleteConfirm.sessions + " Trainingseinheiten." : ".")
                  + "\nDas kann nicht rückgängig gemacht werden."
        }
        onAccepted: {
            const wasSelected = deleteConfirm.athleteId === page.selectedId
            Store.removeAthlete(deleteConfirm.athleteId)
            if (wasSelected)
                page.select("")
        }
    }

    Component.onCompleted: {
        if (Store.athletes.length > 0)
            select(Store.athletes[0].id)
    }
}
