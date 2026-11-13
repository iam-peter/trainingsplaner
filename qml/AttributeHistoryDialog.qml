import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The history of one attribute (Kader, Verein, ...) of an athlete:
// which value applied from when to when. All rows are edited in place
// and saved together; Abbrechen leaves the history as it was.
EditorDialog {
    id: dialog

    property string athleteId
    property string art
    property string error
    // The values offered in every row, read once per opening
    property var values: []

    signal changed()

    // Shared by the headings and the rows; the value takes the rest
    readonly property int wDate: 136
    readonly property int wRemove: 32

    function edit(id, a) {
        athleteId = id
        art = a
        values = Store.attributeValues(art)
        error = ""
        // The rows after opening: rows changed while the dialog is hidden
        // keep the last opening's layout, as Qt does not lay them out anew
        open()
        rows.clear()
        for (const r of Store.attributeHistory(athleteId, art))
            rows.append({ from: r.from, to: r.to, text: r.text })
        // Nothing recorded yet: a row to start typing in
        if (rows.count === 0)
            addRow()
        dirty = false
    }

    function addRow() {
        rows.append({ from: "", to: "", text: "" })
        dirty = true
        // The new row into view, once the list has it
        Qt.callLater(() => { rowList.forceLayout(); rowList.positionViewAtEnd() })
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

    // The old program's title for this window
    title: "Erfassung " + art
    width: parent ? Math.min(parent.width - 40, 640) : 640
    discardText: "Die Änderungen an „" + art + "“ gehen verloren."

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.onTop
        onActivated: dialog.save()
    }

    ListModel { id: rows }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.rightMargin: dialog.wRemove + 8 + rowBar.room
            Label { text: "von"; Layout.preferredWidth: dialog.wDate; font.bold: true }
            Label { text: "bis"; Layout.preferredWidth: dialog.wDate; font.bold: true }
            Label { text: dialog.art; Layout.fillWidth: true; font.bold: true }
        }

        // As high as its rows, until the dialog reaches the window's height;
        // then it scrolls
        ListView {
            id: rowList
            objectName: "rowList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Math.min(contentHeight, 80)
            clip: true
            // The fields' borders sit on the edge: without a pixel around,
            // the clip cut the first row's top line
            topMargin: 1
            bottomMargin: 1
            Layout.preferredHeight: contentHeight + topMargin + bottomMargin
            boundsBehavior: Flickable.StopAtBounds
            spacing: 8
            model: rows
            ScrollBar.vertical: AppScrollBar { id: rowBar }
            delegate: RowLayout {
                id: row
                objectName: "historyRow"
                required property int index
                required property string from
                required property string to
                required property string text
                width: ListView.view.width - rowBar.room
                spacing: 8
                RangeLink { from: rowFrom; to: rowTo; kind: "date" }
                DateField {
                    id: rowFrom
                    objectName: "fromField"
                    Layout.preferredWidth: dialog.wDate
                    text: row.from
                    onTextEdited: { rows.setProperty(row.index, "from", text); dialog.dirty = true }
                }
                DateField {
                    id: rowTo
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
                    model: dialog.values
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
            color: Styles.TokenInterface.semantics.text_muted
        }


        Label {
            Layout.fillWidth: true
            visible: dialog.error !== ""
            wrapMode: Text.Wrap
            text: dialog.error
            color: Styles.TokenInterface.semantics.danger_default
        }
    }

    footer: DialogButtons {
        // On the line of the dialog's buttons, at the left; never part of
        // the scrolled rows
        leading: IconButton {
            objectName: "addButton"
            iconName: "plus"
            text: dialog.art
            onClicked: dialog.addRow()
        }
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
}
