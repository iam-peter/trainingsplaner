import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The history of one attribute (Kader, Verein, ...) of an athlete:
// which value applied from when to when. All rows are edited in place
// and saved together; Abbrechen leaves the history as it was.
AppDialog {
    id: dialog

    property string athleteId
    property string art
    property string error
    property bool dirty: false

    signal changed()

    // Shared by the headings and the rows; the value takes the rest
    readonly property int wDate: 136
    readonly property int wRemove: 32

    function edit(id, a) {
        athleteId = id
        art = a
        rows.clear()
        for (const r of Store.attributeHistory(athleteId, art))
            rows.append({ from: r.from, to: r.to, text: r.text })
        // Nothing recorded yet: a row to start typing in
        if (rows.count === 0)
            addRow()
        error = ""
        dirty = false
        open()
    }

    function addRow() {
        rows.append({ from: "", to: "", text: "" })
        dirty = true
    }

    function save() {
        const list = []
        // Plain objects: the model's own elements reach C++ as empty maps
        for (let i = 0; i < rows.count; ++i) {
            const r = rows.get(i)
            list.push({ from: r.from, to: r.to, text: r.text })
        }
        error = Store.saveAttributeHistory(athleteId, art, list)
        if (error !== "")
            return
        dirty = false
        changed()
        close()
    }

    function cancel() {
        if (dirty)
            discardConfirm.open()
        else
            close()
    }

    // The old program's title for this window
    title: "Erfassung " + art
    width: parent ? Math.min(parent.width - 40, 640) : 640
    closePolicy: Popup.NoAutoClose

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.visible && dialog.level === DialogStack.open
        onActivated: dialog.save()
    }
    // Esc asks before throwing away changes, like Abbrechen
    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: dialog.visible && dialog.level === DialogStack.open
        onActivated: dialog.cancel()
    }

    ListModel { id: rows }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.rightMargin: dialog.wRemove + 8
            Label { text: "von"; Layout.preferredWidth: dialog.wDate; font.bold: true }
            Label { text: "bis"; Layout.preferredWidth: dialog.wDate; font.bold: true }
            Label { text: dialog.art; Layout.fillWidth: true; font.bold: true }
        }

        Repeater {
            model: rows
            RowLayout {
                id: row
                objectName: "historyRow"
                required property int index
                required property string from
                required property string to
                required property string text
                Layout.fillWidth: true
                spacing: 8
                DateField {
                    objectName: "fromField"
                    Layout.preferredWidth: dialog.wDate
                    text: row.from
                    onTextEdited: { rows.setProperty(row.index, "from", text); dialog.dirty = true }
                }
                DateField {
                    objectName: "toField"
                    Layout.preferredWidth: dialog.wDate
                    text: row.to
                    placeholderText: "offen"
                    onTextEdited: { rows.setProperty(row.index, "to", text); dialog.dirty = true }
                }
                ComboBox {
                    objectName: "valueBox"
                    Layout.fillWidth: true
                    editable: true
                    model: Store.attributeValues(dialog.art)
                    // The box sets its text from the list once it has it
                    // (to the first value): the row's value is chosen first,
                    // and only then do changes count
                    property bool ready: false
                    Component.onCompleted: {
                        currentIndex = find(row.text)
                        if (currentIndex < 0)
                            editText = row.text
                        ready = true
                    }
                    onEditTextChanged: if (ready && editText !== row.text) {
                        rows.setProperty(row.index, "text", editText)
                        dialog.dirty = true
                    }
                }
                IconToolButton {
                    objectName: "removeButton"
                    Layout.preferredWidth: dialog.wRemove
                    Layout.preferredHeight: dialog.wRemove
                    iconName: "trash-2"
                    toolTip: "Entfernen"
                    // Removing destroys this row, so it comes last
                    onClicked: {
                        dialog.dirty = true
                        rows.remove(row.index)
                    }
                }
            }
        }

        Label {
            visible: rows.count === 0
            text: "Keine Einträge."
            color: palette.placeholderText
        }

        IconButton {
            objectName: "addButton"
            iconName: "plus"
            text: dialog.art
            onClicked: dialog.addRow()
        }

        Label {
            Layout.fillWidth: true
            visible: dialog.error !== ""
            wrapMode: Text.Wrap
            text: dialog.error
            color: Theme.error
        }
    }

    footer: DialogButtons {
        Button {
            objectName: "cancelButton"
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.cancel()
        }
        IconButton {
            objectName: "saveButton"
            iconName: "save"
            text: "Speichern"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }

    AppDialog {
        id: discardConfirm
        objectName: "discardConfirm"
        title: "Änderungen verwerfen?"
        standardButtons: Dialog.Discard | Dialog.Cancel
        Label { text: "Die Änderungen an „" + dialog.art + "“ gehen verloren." }
        onDiscarded: {
            dialog.dirty = false
            close()
            dialog.close()
        }
    }
}
