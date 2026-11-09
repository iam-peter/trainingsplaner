import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

// Macrocycles (MAZ): dates and phases, and the athletes with their targets.
RowLayout {
    id: pane

    property string mazId
    property bool dirty: false
    property string error
    property var athletes: []

    signal openFramework(string mazId)

    function select(id) {
        mazId = id
        const m = id !== "" ? Plan.maz(id) : null
        nameField.text = m ? m.name : ""
        shortField.text = m ? m.shortName : ""
        men.checked = !m || m.sex === 0
        women.checked = m && m.sex === 1
        fromField.text = m ? m.from : ""
        toField.text = m ? m.to : ""
        buildUpField.text = m ? m.buildUp : ""
        peakField.text = m ? m.peakPhase : ""
        noteField.text = m ? m.note : ""
        error = ""
        dirty = false
        reloadAthletes()
    }

    function reloadAthletes() {
        athletes = mazId !== "" ? Plan.mazAthletes(mazId) : []
    }

    function save() {
        const r = Plan.saveMaz({
            id: mazId, name: nameField.text, shortName: shortField.text, sex: women.checked ? 1 : 0,
            from: fromField.text, to: toField.text, buildUp: buildUpField.text, peakPhase: peakField.text,
            note: noteField.text
        })
        error = r.error
        if (error === "")
            select(r.id)
    }

    spacing: 12

    ListPanel {
        objectName: "mazList"
        Layout.preferredWidth: 300
        Layout.fillHeight: true
        model: Plan.mazList
        emptyText: "Noch kein MAZ."
        addText: "Neuer MAZ"
        onAddClicked: pane.select("")
        delegate: ListRow {
            required property var modelData
            highlighted: modelData.id === pane.mazId
            deleteToolTip: "MAZ löschen"
            onClicked: pane.select(modelData.id)
            onDeleteRequested: {
                deleteConfirm.mazId = modelData.id
                deleteConfirm.name = modelData.displayName
                deleteConfirm.open()
            }
            contentItem: ColumnLayout {
                spacing: 0
                Label { text: modelData.displayName; elide: Text.ElideRight; Layout.fillWidth: true }
                Label {
                    text: modelData.from + " – " + modelData.to + "  ·  " + (modelData.sex === 0 ? "Männer" : "Frauen")
                    font.pixelSize: 11
                    color: palette.placeholderText
                }
            }
        }
    }

    Panel {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            GridLayout {
                columns: 4
                columnSpacing: 12
                rowSpacing: 8

                Label {
                    Layout.columnSpan: 4
                    text: pane.mazId === "" ? "Neuer Makrozyklus" : "Makrozyklus bearbeiten"
                    font.bold: true
                    font.pixelSize: 16
                }
                Label { text: "Bezeichnung:" }
                TextField { id: nameField; Layout.preferredWidth: 260; onTextEdited: pane.dirty = true }
                Label { text: "Kurzbezeichnung:" }
                TextField { id: shortField; Layout.preferredWidth: 100; onTextEdited: pane.dirty = true }
                Label { text: "Für:" }
                RowLayout {
                    spacing: 8
                    RadioButton { id: men; text: "Männer"; onToggled: pane.dirty = true }
                    RadioButton { id: women; text: "Frauen"; onToggled: pane.dirty = true }
                }
                Item {}
                Item {}
                Label { text: "Woche von:" }
                TextField { id: fromField; implicitWidth: 90; placeholderText: "10/2027"; onTextEdited: pane.dirty = true }
                Label { text: "bis:" }
                TextField { id: toField; implicitWidth: 90; placeholderText: "26/2027"; onTextEdited: pane.dirty = true }
                Label { text: "Aufbauphase ab:" }
                TextField { id: buildUpField; implicitWidth: 90; onTextEdited: pane.dirty = true }
                Label { text: "Leistungsausprägung ab:" }
                TextField { id: peakField; implicitWidth: 90; onTextEdited: pane.dirty = true }
                Label { text: "Bemerkung:" }
                TextField { id: noteField; Layout.columnSpan: 3; Layout.fillWidth: true; onTextEdited: pane.dirty = true }
            }

            RowLayout {
                spacing: 8
                IconButton {
                    iconName: pane.mazId === "" ? "plus" : "save"
                    text: pane.mazId === "" ? "Hinzufügen" : "Speichern"
                    highlighted: true
                    enabled: pane.dirty || pane.mazId === ""
                    onClicked: pane.save()
                }
                IconButton {
                    iconName: "target"
                    text: "Rahmenorientierung"
                    enabled: pane.mazId !== ""
                    onClicked: pane.openFramework(pane.mazId)
                }
                IconButton {
                    iconName: "file-down"
                    text: "Export…"
                    enabled: pane.mazId !== ""
                    onClicked: {
                        exportDialog.selectedFile = Store.suggestedExportUrl().toString().replace(/\.bak$/, "_maz.bak")
                        exportDialog.open()
                    }
                }
                Label { text: pane.error; color: Theme.error; visible: pane.error !== "" }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

            Label { text: "Sportler im MAZ"; font.bold: true; visible: pane.mazId !== "" }
            RowLayout {
                visible: pane.mazId !== ""
                spacing: 8
                Label { text: "Sportler"; Layout.preferredWidth: 180; font.pixelSize: 11 }
                Label { text: "Gew.-Kl."; Layout.preferredWidth: 60; font.pixelSize: 11 }
                Label { text: "Ziel Reißen"; Layout.preferredWidth: 70; font.pixelSize: 11 }
                Label { text: "Ziel Stoßen"; Layout.preferredWidth: 70; font.pixelSize: 11 }
                Label { text: "WK Reißen"; Layout.preferredWidth: 70; font.pixelSize: 11 }
                Label { text: "WK Stoßen"; Layout.preferredWidth: 70; font.pixelSize: 11 }
            }
            ListView {
                boundsBehavior: Flickable.StopAtBounds
                visible: pane.mazId !== ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                // The form spacing between the rows of fields
                spacing: 8
                model: pane.athletes
                ScrollBar.vertical: AppScrollBar {}
                delegate: RowLayout {
                    id: athleteRow
                    required property var modelData
                    spacing: 8
                    function saveRow() {
                        Plan.saveMazAthlete({
                            mazId: pane.mazId, athleteId: modelData.athleteId,
                            weightClass: parseInt(wc.text) || 0,
                            targetSnatch: parseInt(ts.text) || 0, targetCleanJerk: parseInt(tc.text) || 0,
                            compSnatch: parseInt(cs.text) || 0, compCleanJerk: parseInt(cc.text) || 0,
                            note: modelData.note
                        })
                    }
                    Label { text: modelData.displayName; Layout.preferredWidth: 180; elide: Text.ElideRight }
                    TextField {
                        id: wc
                        Layout.preferredWidth: 60
                        text: modelData.weightClass || ""
                        validator: IntValidator { bottom: 0; top: 300 }
                        onEditingFinished: athleteRow.saveRow()
                    }
                    TextField {
                        id: ts
                        Layout.preferredWidth: 70
                        text: modelData.targetSnatch || ""
                        validator: IntValidator { bottom: 0; top: 999 }
                        onEditingFinished: athleteRow.saveRow()
                    }
                    TextField {
                        id: tc
                        Layout.preferredWidth: 70
                        text: modelData.targetCleanJerk || ""
                        validator: IntValidator { bottom: 0; top: 999 }
                        onEditingFinished: athleteRow.saveRow()
                    }
                    TextField {
                        id: cs
                        Layout.preferredWidth: 70
                        text: modelData.compSnatch || ""
                        validator: IntValidator { bottom: 0; top: 999 }
                        onEditingFinished: athleteRow.saveRow()
                    }
                    TextField {
                        id: cc
                        Layout.preferredWidth: 70
                        text: modelData.compCleanJerk || ""
                        validator: IntValidator { bottom: 0; top: 999 }
                        onEditingFinished: athleteRow.saveRow()
                    }
                    IconToolButton {
                        iconName: "trash-2"
                        toolTip: "Aus dem MAZ entfernen"
                        onClicked: { Plan.removeMazAthlete(pane.mazId, modelData.athleteId); pane.reloadAthletes() }
                    }
                }
            }
            RowLayout {
                spacing: 8
                visible: pane.mazId !== ""
                ComboBox {
                    id: addAthlete
                    implicitWidth: 220
                    model: Store.selectableAthletes.filter(a => !pane.athletes.some(x => x.athleteId === a.id))
                    textRole: "displayName"
                    valueRole: "id"
                }
                IconButton {
                    iconName: "user-plus"
                    text: "Sportler hinzufügen"
                    enabled: addAthlete.currentIndex >= 0
                    onClicked: {
                        Plan.saveMazAthlete({ mazId: pane.mazId, athleteId: addAthlete.currentValue })
                        pane.reloadAthletes()
                    }
                }
            }
            Item { Layout.fillHeight: true; visible: pane.mazId === "" }
        }
    }

    AppDialog {
        id: deleteConfirm
        property string mazId
        property string name
        title: "MAZ löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: deleteConfirm.name + " wird mit seiner Rahmenorientierung gelöscht.\nDie ITP der Sportler bleiben erhalten." }
        onAccepted: {
            const wasSelected = deleteConfirm.mazId === pane.mazId
            Plan.removeMaz(deleteConfirm.mazId)
            if (wasSelected)
                pane.select("")
        }
    }

    FileDialog {
        id: exportDialog
        title: "MAZ exportieren"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "bak"
        nameFilters: ["Datensicherung (*.bak)"]
        onAccepted: pane.error = Plan.exportMaz(selectedFile, pane.mazId).split("\n")[0]
    }

    Component.onCompleted: select(Plan.mazList.length > 0 ? Plan.mazList[0].id : "")
}
