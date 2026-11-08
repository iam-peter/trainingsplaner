import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The history of one attribute (Kader, Verein, ...) of an athlete:
// which value applied from when to when.
Dialog {
    id: dialog

    property string athleteId
    property string art
    property var records: []
    property string error

    signal changed()

    function edit(id, a) {
        athleteId = id
        art = a
        reload()
        open()
    }

    function reload() {
        records = Store.attributeHistory(athleteId, art)
        error = ""
    }

    title: "Verlauf " + art
    modal: true
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 560
    standardButtons: Dialog.Close

    contentItem: ColumnLayout {
        spacing: 6

        RowLayout {
            spacing: 6
            Label { text: "von"; Layout.preferredWidth: 110; font.bold: true }
            Label { text: "bis"; Layout.preferredWidth: 110; font.bold: true }
            Label { text: dialog.art; Layout.fillWidth: true; font.bold: true }
            Item { Layout.preferredWidth: 72 }
        }

        Repeater {
            model: dialog.records.concat([{ from: "", to: "", text: "", isNew: true }])
            RowLayout {
                id: row
                required property var modelData
                spacing: 6
                TextField {
                    id: fromField
                    Layout.preferredWidth: 110
                    text: row.modelData.from
                    placeholderText: row.modelData.isNew ? "TT.MM.JJJJ" : ""
                }
                TextField {
                    id: toField
                    Layout.preferredWidth: 110
                    text: row.modelData.to
                    placeholderText: "offen"
                }
                ComboBox {
                    id: textField
                    Layout.fillWidth: true
                    editable: true
                    model: Store.attributeValues(dialog.art)
                    editText: row.modelData.text
                }
                IconToolButton {
                    iconName: row.modelData.isNew ? "plus" : "save"
                    toolTip: row.modelData.isNew ? "Hinzufügen" : "Speichern"
                    onClicked: {
                        dialog.error = Store.saveAttributeRecord(dialog.athleteId, dialog.art,
                                                                 row.modelData.isNew ? "" : row.modelData.from,
                                                                 fromField.text, toField.text, textField.editText)
                        if (dialog.error === "") {
                            dialog.reload()
                            dialog.changed()
                        }
                    }
                }
                IconToolButton {
                    visible: !row.modelData.isNew
                    iconName: "trash-2"
                    toolTip: "Löschen"
                    onClicked: {
                        Store.removeAttributeRecord(dialog.athleteId, dialog.art, row.modelData.from)
                        dialog.reload()
                        dialog.changed()
                    }
                }
                Item { visible: row.modelData.isNew; Layout.preferredWidth: 32 }
            }
        }

        Label {
            visible: dialog.error !== ""
            text: dialog.error
            color: "#c00000"
        }
    }
}
