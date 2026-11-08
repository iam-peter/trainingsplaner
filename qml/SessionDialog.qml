import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Editor for one training session ("Trainingseinheit").
Dialog {
    id: dialog

    property string athleteId
    property string monday
    property string variant: "P"
    property int day: 1
    property int number: 1
    property bool exists: false
    property bool dirty: false
    property var weekStats: ({})

    // Initial entry data by uid; the ListModel only holds the uids so that
    // moving or removing rows keeps the other editors intact.
    property var initial: ({})
    property int nextUid: 0

    readonly property var times: {
        const list = []
        for (let h = 6; h <= 21; ++h) {
            for (let m = 0; m < 60; m += 15)
                list.push((h < 10 ? "0" : "") + h + ":" + (m === 0 ? "00" : m))
        }
        return list
    }

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
        fromBox.editText = s.from
        toBox.editText = s.to
        noteField.text = s.note
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

    function validTime(t) {
        return /^\d{1,2}:\d{2}$/.test(t.trim()) ? t.trim() : ""
    }

    function save() {
        Store.saveSession(athleteId, monday, variant, {
            day: day,
            number: number,
            from: validTime(fromBox.editText),
            to: validTime(toBox.editText),
            note: noteField.text,
            entries: collect()
        })
        dirty = false
        close()
    }

    function cancel() {
        if (dirty)
            discardConfirm.open()
        else
            close()
    }

    title: Store.dayName(day) + ", " + Store.dayDate(monday, day) + "  –  " + number + ". TE  ("
           + (variant === "P" ? "Plan" : "Ist") + ")  –  Woche " + Store.weekLabel(monday)
    modal: true
    closePolicy: Popup.NoAutoClose
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: parent ? Math.max(700, Math.min(parent.width - 40, 1100)) : 1000
    height: parent ? Math.max(500, Math.min(parent.height - 40, 820)) : 760
    padding: 10

    Timer {
        id: recalcTimer
        interval: 150
        onTriggered: dialog.recalc()
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.visible
        onActivated: dialog.save()
    }
    Shortcut {
        sequence: "Esc"
        enabled: dialog.visible && !discardConfirm.visible && !deleteConfirm.visible
        onActivated: dialog.cancel()
    }

    ListModel { id: entryModel }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Button {
                text: "+ TÜ"
                onClicked: dialog.addEntry({ kind: 0 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Übung mit Gewichten hinzufügen"
            }
            Button {
                text: "+ AMKT"
                onClicked: dialog.addEntry({ kind: 1 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Allgemeine Übung als Text hinzufügen"
            }
            Button {
                text: "+ Text"
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
            Item { Layout.preferredWidth: 110 }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: entryColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: entryColumn
                width: flick.width - 14
                spacing: 6

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
                        weekStats: dialog.weekStats
                        canMoveUp: index > 0
                        canMoveDown: index < entryRepeater.count - 1
                        onChanged: dialog.markChanged()
                        onRemoveRequested: {
                            entryModel.remove(index)
                            dialog.markChanged()
                        }
                        onMoveRequested: (delta) => {
                            entryModel.move(index, index + delta, 1)
                            dialog.markChanged()
                        }
                    }
                }

                Label {
                    visible: entryModel.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: "Noch keine Übungen. Mit „+ TÜ“, „+ AMKT“ oder „+ Text“ hinzufügen."
                    color: palette.placeholderText
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ColumnLayout {
                spacing: 2
                Label { text: "von:" }
                ComboBox {
                    id: fromBox
                    editable: true
                    model: dialog.times
                    implicitWidth: 90
                    onEditTextChanged: if (activeFocus) dialog.dirty = true
                    onActivated: dialog.dirty = true
                }
            }
            ColumnLayout {
                spacing: 2
                Label { text: "bis:" }
                ComboBox {
                    id: toBox
                    editable: true
                    model: dialog.times
                    implicitWidth: 90
                    onEditTextChanged: if (activeFocus) dialog.dirty = true
                    onActivated: dialog.dirty = true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: "Bemerkung zur TE:" }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    TextArea {
                        id: noteField
                        wrapMode: TextEdit.Wrap
                        onTextChanged: if (activeFocus) dialog.dirty = true
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "TE löschen"
            visible: dialog.exists
            DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
            onClicked: deleteConfirm.open()
        }
        Button {
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.cancel()
        }
        Button {
            text: "Speichern"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
        // The buttons handle closing themselves.
        onAccepted: {}
        onRejected: {}
    }

    Dialog {
        id: discardConfirm
        title: "Änderungen verwerfen?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Discard | Dialog.Cancel
        Label { text: "Die Trainingseinheit wurde geändert und noch nicht gespeichert." }
        onDiscarded: {
            close()
            dialog.dirty = false
            dialog.close()
        }
    }

    Dialog {
        id: deleteConfirm
        title: "Trainingseinheit löschen?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: "Diese Trainingseinheit mit allen Übungen wird gelöscht." }
        onAccepted: {
            Store.removeSession(dialog.athleteId, dialog.monday, dialog.variant, dialog.day, dialog.number)
            dialog.dirty = false
            dialog.close()
        }
    }
}
