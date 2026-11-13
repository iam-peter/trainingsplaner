import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Editor for one training session ("Trainingseinheit"), as a panel beside
// the week instead of a dialog over it, or in a window of its own.
// Changes are saved when another session is chosen or the panel is
// closed, and can be undone like every other change; Speichern (Ctrl+S)
// saves at once.
FocusScope {
    id: editor

    property string athleteId
    property string monday
    property string variant: "P"
    property int day: 1
    property int number: 1
    property bool exists: false
    property var weekStats: ({})
    // Last week and the ITP's targets (Store.weekContext), beside each line
    property var context: ({})
    // A session is being edited
    property bool opened: false
    property bool dirty: false
    // While its own save is stored, so the reload that follows is skipped
    property bool saving: false
    // In a window of its own rather than beside the week
    property bool floating: false

    // Why the session cannot be saved yet, "" when it can
    property string error: ""

    // Initial entry data by uid; the ListModel only holds the uids so that
    // moving or removing rows keeps the other editors intact.
    property var initial: ({})
    property int nextUid: 0

    signal closed()
    signal floatingToggled()

    readonly property string title: Store.dayName(day) + ", " + Store.dayDate(monday, day) + " · " + number + ". TE · "
                                    + (variant === "P" ? "Plan" : "Ist") + " · Woche " + Store.weekLabel(monday)

    function isSession(a, m, v, d, n) {
        return opened && athleteId === a && monday === m && variant === v && day === d && number === n
    }

    // Shows a session; the one shown before is saved first. False when
    // that cannot be saved (an impossible time), which stays then.
    function edit(a, m, v, d, n) {
        // The same again: shown as stored, unless it has changes of its own
        if (isSession(a, m, v, d, n)) {
            if (!dirty)
                reload()
            return true
        }
        if (opened && dirty && !save())
            return false
        athleteId = a
        monday = m
        variant = v
        day = d
        number = n
        reload()
        opened = true
        return true
    }

    // The stored session, again
    function reload() {
        context = Store.weekContext(athleteId, monday)
        const s = Store.session(athleteId, monday, variant, day, number)
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
                if (item)
                    item.focusFirst()
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

    // Saves the session; false, with the reason in error, when it cannot be
    function save() {
        if (!opened)
            return true
        // An impossible time is shown, not dropped
        if (!fromBox.valid || !toBox.valid) {
            error = "„" + (fromBox.valid ? toBox.text : fromBox.text) + "“ ist keine Uhrzeit."
            return false
        }
        if (fromBox.time !== "" && toBox.time !== "" && toBox.time < fromBox.time) {
            error = "„bis“ liegt vor „von“."
            return false
        }
        error = ""
        if (dirty) {
            saving = true
            Store.saveSession(athleteId, monday, variant, {
                day: day,
                number: number,
                from: fromBox.time,
                to: toBox.time,
                note: noteField.text,
                entries: collect()
            })
            saving = false
        }
        dirty = false
        exists = Store.session(athleteId, monday, variant, day, number).exists
        return true
    }

    // Saves and closes; false when it cannot be saved
    function close() {
        if (!opened)
            return true
        if (!save())
            return false
        opened = false
        closed()
        return true
    }

    // The lines of the same session last week (its Ist, else its Plan)
    readonly property var lastWeek: {
        if (!opened)
            return null
        const m = Store.addWeeks(monday, -1)
        for (const v of ["I", "P"]) {
            const s = Store.session(athleteId, m, v, day, number)
            if (s.exists && s.entries.length > 0)
                return { variant: v, label: Store.weekLabel(m), entries: s.entries }
        }
        return null
    }
    function takeLastWeek() {
        if (!lastWeek)
            return
        for (const e of lastWeek.entries)
            addEntry({ kind: e.kind, exercise: e.exercise, steps: e.steps, text: e.text,
                       totalReps: e.totalReps, combination: e.combination }, false)
        markChanged()
    }

    // The field with the focus scrolled into view: a new line, or one
    // reached with Tab. A moment later, once the lines are laid out.
    function ensureVisible(item) {
        let p = item
        while (p && p !== entryColumn)
            p = p.parent
        if (!p)
            return
        const y = item.mapToItem(entryColumn, 0, 0).y
        if (y < flick.contentY)
            flick.contentY = Math.max(0, y - 8)
        else if (y + item.height > flick.contentY + flick.height)
            flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y + item.height - flick.height + 8))
    }
    Timer {
        id: scrollTimer
        interval: 30
        property Item target: null
        onTriggered: if (target) editor.ensureVisible(target)
    }
    Connections {
        target: editor.Window.window
        function onActiveFocusItemChanged() {
            scrollTimer.target = editor.Window.activeFocusItem
            scrollTimer.restart()
        }
    }

    Timer {
        id: recalcTimer
        interval: 150
        onTriggered: editor.recalc()
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: editor.opened && editor.visible && DialogStack.open === 0
        onActivated: editor.save()
    }

    // Esc in the panel closes it (and saves)
    Keys.onEscapePressed: editor.close()

    ListModel { id: entryModel }

    Rectangle {
        anchors.fill: parent
        color: Styles.TokenInterface.semantics.background_elevated
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        border.width: editor.floating ? 0 : 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // The session, and the panel's own buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Label {
                objectName: "editorTitle"
                Layout.fillWidth: true
                text: editor.title
                font.bold: true
                font.pixelSize: 14
                elide: Text.ElideRight
            }
            IconToolButton {
                objectName: "floatButton"
                iconName: editor.floating ? "panel-right" : "external-link"
                toolTip: editor.floating ? "Wieder neben die Woche" : "In ein eigenes Fenster"
                onClicked: editor.floatingToggled()
            }
            IconToolButton {
                objectName: "closeButton"
                iconName: "x"
                toolTip: "Schließen (Esc); Änderungen werden gespeichert"
                onClicked: editor.close()
            }
        }

        // What this panel changes, marked in the week
        Label {
            objectName: "scopeNote"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: Styles.TokenInterface.semantics.text_muted
            text: "Ändert diese Trainingseinheit – in der Woche hervorgehoben."
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
                        source: editor.initial[uid]
                        actual: editor.variant === "I"
                        athleteId: editor.athleteId
                        monday: editor.monday
                        context: editor.context
                        weekStats: editor.weekStats
                        canMoveUp: index > 0
                        canMoveDown: index < entryRepeater.count - 1
                        onChanged: editor.markChanged()
                        // Removing destroys this row, so it comes last
                        onRemoveRequested: {
                            editor.markChanged()
                            entryModel.remove(index)
                        }
                        onInfoRequested: (exercise, chart) =>
                            historyDialog.show(editor.athleteId, editor.monday, editor.variant, exercise, chart)
                        onMoveRequested: (delta) => {
                            entryModel.move(index, index + delta, 1)
                            editor.markChanged()
                        }
                    }
                }

                Label {
                    visible: entryModel.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "Noch keine Übungen. Mit „+ TÜ“, „+ AMKT“ oder „+ Text“ hinzufügen"
                          + (editor.lastWeek ? ", oder die Einheit der Vorwoche übernehmen." : ".")
                    color: Styles.TokenInterface.semantics.text_muted
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            IconButton {
                objectName: "addWeights"
                iconName: "plus"
                text: "TÜ"
                onClicked: editor.addEntry({ kind: 0 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Übung mit Gewichten hinzufügen"
            }
            IconButton {
                iconName: "plus"
                text: "AMKT"
                onClicked: editor.addEntry({ kind: 1 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Allgemeine Übung als Text hinzufügen"
            }
            IconButton {
                iconName: "plus"
                text: "Text"
                onClicked: editor.addEntry({ kind: 2 }, true)
                ToolTip.visible: hovered
                ToolTip.text: "Freien Text hinzufügen"
            }
            Item { Layout.fillWidth: true }
            IconButton {
                objectName: "lastWeekButton"
                visible: entryModel.count === 0 && editor.lastWeek !== null
                iconName: "history"
                text: "Wie Vorwoche"
                onClicked: editor.takeLastWeek()
                ToolTip.visible: hovered
                ToolTip.text: editor.lastWeek ? "Die Übungen dieser Einheit aus Woche " + editor.lastWeek.label
                                                + " (" + (editor.lastWeek.variant === "I" ? "Ist" : "Plan") + ") übernehmen" : ""
            }
        }

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
                    onTextEdited: editor.dirty = true
                }
                Label { text: "bis" }
                TimeField {
                    id: toBox
                    objectName: "toBox"
                    onTextEdited: editor.dirty = true
                }
                RangeLink { from: fromBox; to: toBox }
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
                Layout.preferredHeight: 52
                TextArea {
                    id: noteField
                    objectName: "noteField"
                    placeholderText: "zur Trainingseinheit"
                    wrapMode: TextEdit.Wrap
                    onTextChanged: if (activeFocus) editor.dirty = true
                }
            }
        }

        Label {
            objectName: "errorLabel"
            visible: editor.error !== ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: editor.error
            color: Styles.TokenInterface.semantics.danger_default
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Styles.TokenInterface.semantics.stroke_subtle }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            IconButton {
                objectName: "deleteButton"
                iconName: "trash-2"
                text: "TE löschen"
                visible: editor.exists
                onClicked: deleteConfirm.open()
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: editor.dirty ? "Wird beim Wechsel gespeichert" : editor.exists ? "Gespeichert" : ""
                font.pixelSize: 11
                color: Styles.TokenInterface.semantics.text_muted
            }
            IconButton {
                objectName: "planToActualButton"
                visible: editor.variant === "I" && editor.opened
                         && (Store.dataVersion, Store.session(editor.athleteId, editor.monday, "P", editor.day, editor.number).exists)
                enabled: !editor.dirty
                iconName: "copy"
                text: "Ist = Plan"
                toolTip: "Die geplante Einheit als Ist übernehmen, dann ändern, was anders war"
                onClicked: {
                    Store.planToActual(editor.athleteId, editor.monday, editor.day, editor.number)
                    editor.reload()
                }
            }
            IconButton {
                objectName: "saveButton"
                iconName: "save"
                text: "Speichern"
                highlighted: true
                enabled: editor.dirty
                toolTip: "Jetzt speichern (Strg+S)"
                onClicked: editor.save()
            }
        }
    }

    ExerciseHistoryDialog {
        id: historyDialog
    }

    AppDialog {
        id: deleteConfirm
        objectName: "deleteConfirm"
        title: "Trainingseinheit löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: "Diese Trainingseinheit mit allen Übungen wird gelöscht." }
        onAccepted: {
            Store.removeSession(editor.athleteId, editor.monday, editor.variant, editor.day, editor.number)
            editor.dirty = false
            editor.close()
        }
    }
}
