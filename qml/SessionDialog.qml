import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Editor for one training session ("Trainingseinheit").
EditorDialog {
    id: dialog

    property string athleteId
    property string monday
    property string variant: "P"
    property int day: 1
    property int number: 1
    property bool exists: false
    property var weekStats: ({})

    // Initial entry data by uid; the ListModel only holds the uids so that
    // moving or removing rows keeps the other editors intact.
    property var initial: ({})
    property int nextUid: 0


    function edit(a, m, v, d, n) {
        athleteId = a
        monday = m
        variant = v
        day = d
        number = n
        const s = Store.session(a, m, v, d, n)
        exists = s.exists
        entryModel.clear()
        initial = {}
        for (const e of s.entries)
            addEntry(e, false)
        fromBox.text = s.from
        toBox.text = s.to
        noteField.text = s.note
        error = ""
        dirty = false
        open()
        recalc()
    }

    function addEntry(map, focus) {
        const uid = nextUid++
        initial[uid] = map
        entryModel.append({ uid: uid })
        if (focus) {
            dirty = true
            Qt.callLater(() => {
                const item = entryRepeater.itemAt(entryRepeater.count - 1)
                if (item) {
                    item.focusFirst()
                    flick.contentY = Math.max(0, flick.contentHeight - flick.height)
                }
            })
        }
    }

    function collect() {
        const list = []
        for (let i = 0; i < entryRepeater.count; ++i) {
            const item = entryRepeater.itemAt(i)
            if (item)
                list.push(item.value())
        }
        return list
    }

    function recalc() {
        weekStats = Store.weekStats(athleteId, monday, variant, day, number, collect())
    }

    function markChanged() {
        dirty = true
        recalcTimer.restart()
    }

    // Why the session cannot be saved yet, "" when it can
    property string error: ""

    function save() {
        // An impossible time is shown, not dropped
        if (!fromBox.valid || !toBox.valid) {
            error = "„" + (fromBox.valid ? toBox.text : fromBox.text) + "“ ist keine Uhrzeit."
            return
        }
        if (fromBox.time !== "" && toBox.time !== "" && toBox.time < fromBox.time) {
            error = "„bis“ liegt vor „von“."
            return
        }
        error = ""
        Store.saveSession(athleteId, monday, variant, {
            day: day,
            number: number,
            from: fromBox.time,
            to: toBox.time,
            note: noteField.text,
            entries: collect()
        })
        dirty = false
        close()
    }

    title: Store.dayName(day) + ", " + Store.dayDate(monday, day) + "  –  " + number + ". TE  ("
           + (variant === "P" ? "Plan" : "Ist") + ")  –  Woche " + Store.weekLabel(monday)
    discardText: "Die Trainingseinheit wurde geändert und noch nicht gespeichert."
    width: parent ? Math.max(700, Math.min(parent.width - 40, 1100)) : 1000
    height: parent ? Math.max(500, Math.min(parent.height - 40, 820)) : 760

    Timer {
        id: recalcTimer
        interval: 150
        onTriggered: dialog.recalc()
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.onTop
        onActivated: dialog.save()
    }

    ListModel { id: entryModel }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconButton {
                iconName: "plus"
                text: "TÜ"
                onClicked: dialog.addEntry({ kind: 0 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Übung mit Gewichten hinzufügen"
            }
            IconButton {
                iconName: "plus"
                text: "AMKT"
                onClicked: dialog.addEntry({ kind: 1 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Allgemeine Übung als Text hinzufügen"
            }
            IconButton {
                iconName: "plus"
                text: "Text"
                onClicked: dialog.addEntry({ kind: 2 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Freien Text hinzufügen"
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "MHG (Woche)\nWH (Woche)"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 76
            }
            Label {
                text: "BW (Woche)\nSG/ANZ (Woche)"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 90
            }
            Item { Layout.preferredWidth: 170 }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: entryColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}

            ColumnLayout {
                id: entryColumn
                width: flick.width - flick.ScrollBar.vertical.room
                spacing: 8

                Repeater {
                    id: entryRepeater
                    model: entryModel
                    EntryEditor {
                        required property int index
                        objectName: "entry" + index
                        required property int uid
                        Layout.fillWidth: true
                        source: dialog.initial[uid]
                        actual: dialog.variant === "I"
                        athleteId: dialog.athleteId
                        monday: dialog.monday
                        weekStats: dialog.weekStats
                        canMoveUp: index > 0
                        canMoveDown: index < entryRepeater.count - 1
                        onChanged: dialog.markChanged()
                        // Removing destroys this row, so it comes last
                        onRemoveRequested: {
                            dialog.markChanged()
                            entryModel.remove(index)
                        }
                        onInfoRequested: (exercise, chart) =>
                            historyDialog.show(dialog.athleteId, dialog.monday, dialog.variant, exercise, chart)
                        onMoveRequested: (delta) => {
                            entryModel.move(index, index + delta, 1)
                            dialog.markChanged()
                        }
                    }
                }

                Label {
                    visible: entryModel.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "Noch keine Übungen. Mit „+ TÜ“, „+ AMKT“ oder „+ Text“ hinzufügen."
                    color: Styles.TokenInterface.semantics.text_muted
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Styles.TokenInterface.semantics.stroke_subtle }

        // Time and note as a form: labels in one column, fields beside them
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8
            Label { text: "Zeit:" }
            RowLayout {
                spacing: 8
                TimeField {
                    id: fromBox
                    objectName: "fromBox"
                    onTextEdited: dialog.dirty = true
                }
                Label { text: "bis" }
                TimeField {
                    id: toBox
                    objectName: "toBox"
                    onTextEdited: dialog.dirty = true
                }
                RangeLink { from: fromBox; to: toBox }
                Label {
                    objectName: "errorLabel"
                    visible: dialog.error !== ""
                    text: dialog.error
                    color: Styles.TokenInterface.semantics.danger_default
                }
            }
            Label {
                text: "Bemerkung:"
                Layout.alignment: Qt.AlignTop
                // On the line of the note's first row of text
                topPadding: noteField.topPadding
            }
            ScrollView {
                // No overshoot at the ends
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                TextArea {
                    id: noteField
                    objectName: "noteField"
                    placeholderText: "zur Trainingseinheit"
                    wrapMode: TextEdit.Wrap
                    onTextChanged: if (activeFocus) dialog.dirty = true
                }
            }
        }
    }

    footer: DialogButtons {
        leading: IconButton {
            objectName: "deleteButton"
            iconName: "trash-2"
            text: "TE löschen"
            visible: dialog.exists
            DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
            onClicked: deleteConfirm.open()
        }
        Button {
            objectName: "cancelButton"
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.cancel()
        }
        IconButton {
            iconName: "save"
            text: "Speichern"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }

    ExerciseHistoryDialog {
        id: historyDialog
    }

    AppDialog {
        id: deleteConfirm
        title: "Trainingseinheit löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: "Diese Trainingseinheit mit allen Übungen wird gelöscht." }
        onAccepted: {
            Store.removeSession(dialog.athleteId, dialog.monday, dialog.variant, dialog.day, dialog.number)
            dialog.dirty = false
            dialog.close()
        }
    }
}
