import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// "Erfassung TÜ" as the panel's second view: one exercise across the
// whole week, one row for each session it is in. It changes that
// exercise's lines in every session of the week: their weight steps, the
// session a line is in (day, TE), and adds or removes the exercise in a
// session. Saved like the session panel: when another session or
// exercise is chosen, the week changes or the panel closes.
FocusScope {
    id: editor

    property string athleteId
    property string monday
    property string variant: "P"
    property int exercise: 0
    property bool opened: false
    property bool dirty: false
    property bool saving: false
    property bool floating: false
    property bool valid: false
    property var weekStats: ({})
    // Last week and the ITP's targets (Store.weekContext)
    property var context: ({})
    // How much the athlete usually adds per step, for the proposals
    readonly property real jump: (Store.dataVersion, exercise > 0 && athleteId !== "" ? Store.usualJump(athleteId, monday, exercise) : 5)
    // The athlete's earlier lines of the exercise, offered in each row
    readonly property var recentSteps: (Store.dataVersion, exercise > 0 && athleteId !== "" ? Store.recentSteps(athleteId, exercise) : [])

    // The session of the row under the pointer, for the week to mark
    readonly property int hoveredDay: hoveredRow ? hoveredRow.day : 0
    readonly property int hoveredNumber: hoveredRow ? hoveredRow.number : 0
    readonly property var hoveredRow: {
        for (let i = 0; i < rowRepeater.count; ++i) {
            const item = rowRepeater.itemAt(i)
            if (item && item.pointerOver)
                return item
        }
        return null
    }

    // Initial row data by uid, as in the session panel
    property var initial: ({})
    property int nextUid: 0
    property var copiedSteps: null

    signal closed()
    signal floatingToggled()

    readonly property string title: "TÜ " + (exercise > 0 ? exercise + " " + Store.exerciseName(exercise) : "")
                                    + " · Woche " + Store.weekLabel(monday) + " · " + (variant === "P" ? "Plan" : "Ist")

    function isExercise(a, m, v, ex) {
        return opened && athleteId === a && monday === m && variant === v && exercise === ex
    }

    // Shows an exercise of a week; the one shown before is saved first
    function edit(a, m, v, ex) {
        if (isExercise(a, m, v, ex)) {
            if (!dirty)
                reload()
            return true
        }
        if (opened && dirty && !save())
            return false
        athleteId = a
        monday = m
        variant = v
        exercise = ex
        reload()
        opened = true
        return true
    }

    function reload() {
        context = Store.weekContext(athleteId, monday)
        const data = Store.exerciseWeek(athleteId, monday, variant, exercise)
        valid = data.valid
        numberField.text = exercise > 0 ? exercise : ""
        rowModel.clear()
        initial = {}
        for (const r of data.rows)
            addRow(r, false)
        dirty = false
        recalc()
    }

    // Another exercise from the number field or the picker
    function switchTo(ex) {
        // Also called when the number field loses the focus as the panel
        // closes: nothing to switch then
        if (!opened || ex === exercise)
            return
        if (!edit(athleteId, monday, variant, ex))
            numberField.text = exercise > 0 ? exercise : ""
    }

    function addRow(r, focus) {
        const uid = nextUid++
        initial[uid] = r
        rowModel.append({ uid: uid })
        if (focus) {
            dirty = true
            Qt.callLater(() => {
                const item = rowRepeater.itemAt(rowRepeater.count - 1)
                if (item)
                    item.focusFirst()
            })
        }
    }

    // A new row goes to the day after the last one, in the same session
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
        if (!opened)
            return true
        if (dirty && valid) {
            saving = true
            Store.saveExerciseWeek(athleteId, monday, variant, exercise, collect())
            saving = false
        }
        dirty = false
        return true
    }

    function close() {
        if (!opened)
            return true
        if (!save())
            return false
        opened = false
        closed()
        return true
    }

    // The field with the focus scrolled into view
    function ensureVisible(item) {
        let p = item
        while (p && p !== rowColumn)
            p = p.parent
        if (!p)
            return
        const y = item.mapToItem(rowColumn, 0, 0).y
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
        enabled: editor.opened && editor.visible && editor.valid && DialogStack.open === 0
        onActivated: editor.save()
    }

    Keys.onEscapePressed: editor.close()

    ListModel { id: rowModel }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Label {
                objectName: "editorTitle"
                Layout.fillWidth: true
                text: "Erfassung TÜ · Woche " + Store.weekLabel(editor.monday) + " · " + (editor.variant === "P" ? "Plan" : "Ist")
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

        // What this view changes, marked in the week
        Label {
            objectName: "scopeNote"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: Styles.TokenInterface.semantics.text_muted
            text: editor.valid
                  ? "Ändert Übung " + editor.exercise + " in allen Einheiten dieser Woche – in der Woche hervorgehoben. "
                    + "Je Zeile eine Einheit; Tag und TE verlegen sie."
                  : "Eine Übung mit Gewichten wählen."
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            // The number and its picker, one group
            RowLayout {
                spacing: -Styles.Primitives.stroke.thin
                TextField {
                    id: numberField
                    objectName: "exerciseField"
                    groupPosition: Styles.GroupStyle.Position.First
                    implicitWidth: 46
                    horizontalAlignment: TextInput.AlignHCenter
                    font.bold: true
                    font.pixelSize: 15
                    validator: IntValidator { bottom: 0; top: 99 }
                    error: !editor.valid
                    onEditingFinished: editor.switchTo(parseInt(text) || 0)
                    ToolTip.visible: activeFocus
                    ToolTip.text: "Andere Übung: Nummer eingeben und Enter"
                }
                IconButton {
                    implicitHeight: numberField.height
                    groupPosition: Styles.GroupStyle.Position.Last
                    iconName: "layout-grid"
                    toolTip: "Übung auswählen"
                    onClicked: picker.open()
                    ExercisePicker {
                        id: picker
                        y: parent.height + 2
                        textExercises: false
                        current: editor.exercise
                        onPicked: (id) => editor.switchTo(id)
                    }
                }
            }
            Label {
                objectName: "exerciseName"
                Layout.fillWidth: true
                text: editor.valid ? Store.exerciseName(editor.exercise)
                      : editor.exercise > 0 ? "Keine Übung mit Gewichten" : "Übung wählen"
                color: editor.valid ? Styles.TokenInterface.semantics.text_default : Styles.TokenInterface.semantics.danger_default
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }
            IconToolButton {
                iconName: "list"
                toolTip: "Info: frühere Einheiten dieser Übung"
                enabled: editor.valid
                onClicked: historyDialog.show(editor.athleteId, editor.monday, editor.variant, editor.exercise, false)
            }
            IconToolButton {
                iconName: "chart-line"
                toolTip: "Grafik der letzten Wochen"
                enabled: editor.valid
                onClicked: historyDialog.show(editor.athleteId, editor.monday, editor.variant, editor.exercise, true)
            }
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
                        source: editor.initial[uid]
                        actual: editor.variant === "I"
                        jump: editor.jump
                        suggestions: editor.recentSteps
                        onChanged: editor.markChanged()
                        canPaste: editor.copiedSteps !== null
                        onCopyRequested: (steps) => editor.copiedSteps = steps
                        onPasteRequested: setSteps(editor.copiedSteps)
                        // Removing destroys this row, so it comes last
                        onRemoveRequested: {
                            editor.markChanged()
                            rowModel.remove(index)
                        }
                    }
                }

                Label {
                    visible: rowModel.count === 0 && editor.valid
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    horizontalAlignment: Text.AlignHCenter
                    text: "Diese Übung ist in der Woche noch nicht geplant."
                    color: Styles.TokenInterface.semantics.text_muted
                }

                IconButton {
                    objectName: "addRow"
                    enabled: editor.valid
                    iconName: "plus"
                    text: "Einheit hinzufügen"
                    onClicked: editor.addNewRow()
                }
            }
        }

        // The exercise's week: its figures, last week and the ITP
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label {
                objectName: "weekFigures"
                Layout.fillWidth: true
                font.bold: true
                elide: Text.ElideRight
                text: "Woche:  WH " + (editor.weekStats.wh || 0) + " · MHG " + (editor.weekStats.mhg || 0)
                      + " · BW " + (editor.weekStats.bw || 0) + (editor.weekStats.repsSets ? " (" + editor.weekStats.repsSets + ")" : "")
                      + " · " + ((editor.weekStats.tonnage || 0) / 1000).toLocaleString(Qt.locale("de_DE"), "f", 1) + " t"
            }
            Label {
                objectName: "previousWeek"
                readonly property var prev: editor.valid && editor.context.previous
                                            ? editor.context.previous.perExercise[String(editor.exercise)] : undefined
                visible: prev !== undefined && !prev.empty
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: prev ? "Vorwoche" + (editor.context.previous.variant === "P" ? " (Plan)" : "")
                             + ":  WH " + prev.wh + " · MHG " + prev.mhg + " · BW " + prev.bw : ""
                color: Styles.TokenInterface.semantics.text_muted
            }
            Label {
                readonly property var itp: editor.valid && editor.opened
                                           ? (Plan.mazList, Plan.itpForWeek(editor.athleteId, editor.monday, editor.exercise)) : null
                visible: itp !== null && itp.has
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: itp ? "ITP:  WH " + itp.wh + " · MHG " + itp.mhg + " · BW " + itp.bw
                            + (itp.steps !== "" ? "   Laststufen ITP: " + itp.steps : "") : ""
                color: Styles.TokenInterface.semantics.primary_default
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Styles.TokenInterface.semantics.stroke_subtle }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: editor.dirty ? "Wird beim Wechsel gespeichert" : ""
                font.pixelSize: 11
                color: Styles.TokenInterface.semantics.text_muted
            }
            IconButton {
                objectName: "saveButton"
                iconName: "save"
                text: "Speichern"
                highlighted: true
                enabled: editor.dirty && editor.valid
                toolTip: "Jetzt speichern (Strg+S)"
                onClicked: editor.save()
            }
        }
    }

    ExerciseHistoryDialog {
        id: historyDialog
    }
}
