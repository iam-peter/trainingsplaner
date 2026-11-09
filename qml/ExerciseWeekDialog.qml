import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// "Erfassung TÜ": one exercise across the whole week, one row for each
// session it appears in.
EditorDialog {
    id: dialog

    property string athleteId
    property string monday
    property string variant: "P"
    property int exercise: 0
    property bool valid: false
    property var weekStats: ({})

    // Initial row data by uid, as in SessionDialog
    property var initial: ({})
    property int nextUid: 0
    property var copiedSteps: null

    function edit(a, m, v, ex) {
        athleteId = a
        monday = m
        variant = v
        load(ex)
        open()
    }

    function load(ex) {
        const data = Store.exerciseWeek(athleteId, monday, variant, ex)
        exercise = ex
        valid = data.valid
        numberField.text = ex > 0 ? ex : ""
        rowModel.clear()
        initial = {}
        for (const r of data.rows)
            addRow(r, false)
        dirty = false
        recalc()
    }

    function switchTo(ex) {
        if (ex === exercise)
            return
        if (dirty)
            askDiscard(() => load(ex), () => numberField.text = exercise > 0 ? exercise : "")
        else
            load(ex)
    }

    function addRow(r, focus) {
        const uid = nextUid++
        initial[uid] = r
        rowModel.append({ uid: uid })
        if (focus) {
            dirty = true
            Qt.callLater(() => {
                const item = rowRepeater.itemAt(rowRepeater.count - 1)
                if (item) {
                    item.focusFirst()
                    flick.contentY = Math.max(0, flick.contentHeight - flick.height)
                }
            })
        }
    }

    // A new row goes to the day after the last one, in the same session.
    function addNewRow() {
        const rows = collect()
        const last = rows.length > 0 ? rows[rows.length - 1] : null
        addRow({
            origIndex: -1,
            day: last ? Math.min(7, last.day + 1) : 1,
            number: last ? last.number : 1,
            steps: []
        }, true)
        recalc()
    }

    function collect() {
        const list = []
        for (let i = 0; i < rowRepeater.count; ++i) {
            const item = rowRepeater.itemAt(i)
            if (item)
                list.push(item.value())
        }
        return list
    }

    function recalc() {
        let all = []
        for (const r of collect())
            all = all.concat(r.steps)
        weekStats = Store.stats(all)
    }

    function markChanged() {
        dirty = true
        recalcTimer.restart()
    }

    function save() {
        if (valid)
            Store.saveExerciseWeek(athleteId, monday, variant, exercise, collect())
        dirty = false
        close()
    }

    title: "Erfassung TÜ " + (exercise > 0 ? exercise : "") + "  –  Woche " + Store.weekLabel(monday)
           + "  (" + (variant === "P" ? "Plan" : "Ist") + ")"
    discardText: "Die Übung wurde geändert und noch nicht gespeichert."
    width: parent ? Math.max(700, Math.min(parent.width - 40, 1100)) : 1000
    height: parent ? Math.max(500, Math.min(parent.height - 40, 820)) : 760
    // Fixed height; scrolls its content itself
    scrollsContent: false

    Timer {
        id: recalcTimer
        interval: 150
        onTriggered: dialog.recalc()
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.onTop && dialog.valid
        onActivated: dialog.save()
    }

    ListModel { id: rowModel }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: numberField
                objectName: "exerciseField"
                implicitWidth: 46
                horizontalAlignment: TextInput.AlignHCenter
                font.bold: true
                font.pixelSize: 15
                validator: IntValidator { bottom: 0; top: 99 }
                color: dialog.valid ? palette.text : Theme.error
                onEditingFinished: dialog.switchTo(parseInt(text) || 0)
                ToolTip.visible: activeFocus
                ToolTip.text: "Andere Übung: Nummer eingeben und Enter"
            }
            IconButton {
                implicitHeight: numberField.height
                iconName: "layout-grid"
                toolTip: "Übung auswählen"
                onClicked: picker.open()
                ExercisePicker {
                    id: picker
                    y: parent.height + 2
                    textExercises: false
                    current: dialog.exercise
                    onPicked: (id) => dialog.switchTo(id)
                }
            }
            Label {
                Layout.fillWidth: true
                text: dialog.valid ? Store.exerciseName(dialog.exercise)
                      : dialog.exercise > 0 ? "Keine Übung mit Gewichten" : "Übung wählen"
                color: dialog.valid ? palette.text : Theme.error
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }
            IconButton {
                iconName: "list"
                toolTip: "Info: frühere Einheiten dieser Übung"
                enabled: dialog.valid
                onClicked: historyDialog.show(dialog.athleteId, dialog.monday, dialog.variant, dialog.exercise, false)
            }
            IconButton {
                iconName: "chart-line"
                toolTip: "Grafik der letzten Wochen"
                enabled: dialog.valid
                onClicked: historyDialog.show(dialog.athleteId, dialog.monday, dialog.variant, dialog.exercise, true)
            }
            Label {
                text: "MHG\nWH"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 50
            }
            Label {
                text: "BW\nSG/ANZ"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 50
            }
            Item { Layout.preferredWidth: 104 }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: rowColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}

            ColumnLayout {
                id: rowColumn
                width: flick.width - flick.ScrollBar.vertical.room
                spacing: 8

                Repeater {
                    id: rowRepeater
                    model: rowModel
                    ExerciseRowEditor {
                        required property int index
                        required property int uid
                        objectName: "row" + index
                        Layout.fillWidth: true
                        source: dialog.initial[uid]
                        actual: dialog.variant === "I"
                        onChanged: dialog.markChanged()
                        canPaste: dialog.copiedSteps !== null
                        onCopyRequested: (steps) => dialog.copiedSteps = steps
                        onPasteRequested: setSteps(dialog.copiedSteps)
                        // Removing destroys this row, so it comes last
                        onRemoveRequested: {
                            dialog.markChanged()
                            rowModel.remove(index)
                        }
                    }
                }

                Label {
                    visible: rowModel.count === 0 && dialog.valid
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "Diese Übung ist in der Woche noch nicht geplant."
                    color: palette.placeholderText
                }

                IconButton {
                    objectName: "addRow"
                    enabled: dialog.valid
                    iconName: "plus"
                    text: "Einheit hinzufügen"
                    onClicked: dialog.addNewRow()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            Label {
                text: "Woche"
                font.bold: true
            }
            Label { text: "WH " + (dialog.weekStats.wh || 0) }
            Label { text: "MHG " + (dialog.weekStats.mhg || 0) }
            Label { text: "BW " + (dialog.weekStats.bw || 0) + (dialog.weekStats.repsSets ? "  (" + dialog.weekStats.repsSets + ")" : "") }
            Label { text: "Tonnage " + ((dialog.weekStats.tonnage || 0) / 1000).toLocaleString(Qt.locale("de_DE"), "f", 1) + " t" }
            Item { Layout.fillWidth: true }
            Label {
                readonly property var itp: dialog.valid ? (Plan.changed, Plan.itpForWeek(dialog.athleteId, dialog.monday, dialog.exercise)) : null
                visible: itp !== null && itp.has
                text: itp ? "ITP:  WH " + itp.wh + "  MHG " + itp.mhg + "  BW " + itp.bw
                            + (itp.steps !== "" ? "   Laststufen ITP: " + itp.steps : "") : ""
                color: Theme.accent
                font.bold: true
            }
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
            iconName: "save"
            text: "Speichern"
            highlighted: true
            enabled: dialog.valid
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }

    ExerciseHistoryDialog {
        id: historyDialog
    }

}
