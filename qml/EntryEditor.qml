import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// One line of a training session: an exercise with weight steps, a general
// exercise described in text, or a free text note.
Frame {
    id: editor

    // Initial content (entry map from Store); read once.
    property var source: ({})
    property bool actual: false     // "Ist" week: also ask for failed attempts
    property var weekStats: ({})
    property bool canMoveUp: false
    property bool canMoveDown: false
    // Whose week this is, for the proposals while typing
    property string athleteId
    property string monday
    // Last week and the ITP's targets (Store.weekContext)
    property var context: ({})

    // "Vorwoche WH 18 · MHG 54 · BW 60   ITP WH 18 · MHG 56 · BW 62"
    readonly property string comparison: {
        if (kind !== 0 || exercise <= 0)
            return ""
        const parts = []
        const prev = context.previous && context.previous.perExercise ? context.previous.perExercise[String(exercise)] : undefined
        if (prev && !prev.empty)
            parts.push("Vorwoche" + (context.previous.variant === "P" ? " (Plan)" : "") + "  WH " + prev.wh
                       + " · MHG " + prev.mhg + " · BW " + prev.bw)
        const itp = context.target && context.target.perExercise ? context.target.perExercise[String(exercise)] : undefined
        if (itp)
            parts.push("ITP  WH " + itp.wh + " · MHG " + itp.mhg + " · BW " + itp.bw)
        return parts.join("      ")
    }

    property int kind: 0            // 0 weights, 1 exercise text, 2 free text
    property int exercise: 0
    property string entryText: ""
    property int totalReps: 0
    property int combination: 0
    // "WH (ges.)" typed by hand; until then it follows the text (4x12 → 48)
    property bool repsTyped: false
    readonly property var entryStats: stepsEditor.stats

    signal changed()
    signal removeRequested()
    signal moveRequested(int delta)
    signal infoRequested(int exercise, bool chart)

    readonly property var exerciseInfo: {
        for (const e of Store.catalog) {
            if (e.id === exercise)
                return e
        }
        return null
    }
    readonly property bool exerciseValid: exerciseInfo !== null && exerciseInfo.text === (kind === 1)
    readonly property var week: weekStats[String(exercise)] || null

    function value() {
        return {
            kind: kind,
            exercise: exercise,
            steps: stepsEditor.value(),
            text: entryText,
            totalReps: totalReps,
            combination: combination
        }
    }

    // Total reps of a text such as "4x12" or "3x10 + 2x8"; 0 when the
    // text holds anything else ("4xMax", "Athletik"), so nothing is filled
    function repsFromText(t) {
        const terms = t.split(/[+,;]/).map(x => x.trim()).filter(x => x !== "")
        if (terms.length === 0)
            return 0
        let sum = 0
        for (const term of terms) {
            const m = term.match(/^(\d+)\s*[x×*]\s*(\d+)$/i)
            if (!m)
                return 0
            sum += parseInt(m[1]) * parseInt(m[2])
        }
        return sum
    }

    // The text changed: the total follows unless it was typed by hand
    function takeText(text, reps) {
        entryText = text
        if (!repsTyped) {
            totalReps = reps !== undefined && reps > 0 ? reps : repsFromText(text)
            repsField.text = totalReps > 0 ? totalReps : ""
        }
        changed()
    }

    function focusFirst() {
        if (kind === 2)
            freeTextField.forceActiveFocus()
        else
            numberField.forceActiveFocus()
    }

    Component.onCompleted: {
        kind = source.kind || 0
        exercise = source.exercise || 0
        entryText = source.text || ""
        totalReps = source.totalReps || 0
        combination = source.combination || 0
        // A stored total that the text does not give was typed by hand
        repsTyped = totalReps > 0 && totalReps !== repsFromText(entryText)
    }

    // Two rows, to fit beside the week: the exercise with its figures and
    // buttons, then its weights or text
    padding: 10
    background: Rectangle {
        color: Styles.TokenInterface.semantics.background_default
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        radius: Styles.Primitives.radius.r4
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Exercise number with picker
            TextField {
                id: numberField
                objectName: "exerciseField"
                visible: editor.kind !== 2
                implicitWidth: 42
                horizontalAlignment: TextInput.AlignHCenter
                font.bold: true
                font.pixelSize: 15
                validator: IntValidator { bottom: 0; top: 99 }
                text: editor.exercise > 0 ? editor.exercise : ""
                onTextEdited: {
                    editor.exercise = parseInt(text) || 0
                    editor.changed()
                }
                error: text !== "" && !editor.exerciseValid

                ExercisePicker {
                    id: picker
                    y: numberField.height + 2
                    textExercises: editor.kind === 1
                    current: editor.exercise
                    onPicked: (id) => {
                        editor.exercise = id
                        editor.changed()
                        if (editor.kind === 0)
                            stepsEditor.focusFirst()
                        else if (editor.kind === 1)
                            exerciseTextField.forceActiveFocus()
                    }
                }
            }
            IconButton {
                visible: editor.kind !== 2
                implicitWidth: 30
                implicitHeight: numberField.height
                iconName: "layout-grid"
                toolTip: "Übung auswählen"
                onClicked: picker.open()
            }
            Label {
                objectName: "exerciseName"
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: editor.kind === 2 ? "Text"
                      : editor.exercise === 0 ? (editor.kind === 1 ? "AMKT-Übung" : "Übung")
                      : editor.exerciseValid ? editor.exerciseInfo.name + (editor.kind === 1 ? "  · AMKT" : "")
                      : editor.exerciseInfo ? "Nr. nicht für " + (editor.kind === 1 ? "Text" : "Gewichte")
                      : "unbekannte Nr."
                elide: Text.ElideRight
                font.bold: editor.exerciseValid
                color: editor.exercise !== 0 && !editor.exerciseValid && editor.kind !== 2
                       ? Styles.TokenInterface.semantics.danger_default
                       : editor.exerciseValid ? Styles.TokenInterface.semantics.text_default
                       : Styles.TokenInterface.semantics.text_muted
            }
            // Info, move, remove; out of the Tab order, which goes from the
            // exercise straight to its weights
            RowLayout {
                Layout.rightMargin: -6
                spacing: 0
                IconToolButton {
                    activeFocusOnTab: false
                    visible: editor.kind === 0
                    enabled: editor.exerciseValid
                    iconName: "list"
                    toolTip: "Info: frühere Einheiten dieser Übung"
                    onClicked: editor.infoRequested(editor.exercise, false)
                }
                IconToolButton {
                    activeFocusOnTab: false
                    visible: editor.kind === 0
                    enabled: editor.exerciseValid
                    iconName: "chart-line"
                    toolTip: "Grafik der letzten Wochen"
                    onClicked: editor.infoRequested(editor.exercise, true)
                }
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "arrow-up"
                    toolTip: "Nach oben"
                    enabled: editor.canMoveUp
                    onClicked: editor.moveRequested(-1)
                }
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "arrow-down"
                    toolTip: "Nach unten"
                    enabled: editor.canMoveDown
                    onClicked: editor.moveRequested(1)
                }
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "trash-2"
                    toolTip: "Zeile entfernen"
                    onClicked: editor.removeRequested()
                }
            }
        }

        // Weight steps, and under them last week and the ITP
        StepsEditor {
            id: stepsEditor
            visible: editor.kind === 0
            Layout.fillWidth: true
            initialSteps: editor.source.steps || []
            actual: editor.actual
            jump: editor.kind === 0 && editor.exercise > 0 ? Store.usualJump(editor.athleteId, editor.monday, editor.exercise) : 5
            suggestions: editor.kind === 0 && editor.exercise > 0 ? Store.recentSteps(editor.athleteId, editor.exercise) : []
            onChanged: editor.changed()
        }
        // Under the weights, past the "KG:" labels: this session's figures,
        // the week's in brackets, as WinWoTA's "TE (WO)"; then last week and
        // the ITP
        RowLayout {
            visible: editor.kind === 0
            Layout.fillWidth: true
            Layout.leftMargin: stepsEditor.stepsX
            spacing: 16
            Label {
                objectName: "figures"
                text: "WH " + (editor.entryStats.wh || 0) + " (" + (editor.week ? editor.week.wh : 0) + ")"
                      + " · MHG " + (editor.entryStats.mhg || 0) + " (" + (editor.week ? editor.week.mhg : 0) + ")"
                      + " · BW " + (editor.entryStats.bw || 0) + " (" + (editor.week ? editor.week.bw : 0) + ")"
                      + (editor.entryStats.repsSets ? " " + editor.entryStats.repsSets : "")
                font.bold: true
                font.pixelSize: 12
                HoverHandler { id: figuresHover }
                ToolTip.visible: figuresHover.hovered
                ToolTip.delay: 400
                ToolTip.text: "Diese Einheit, in Klammern die ganze Woche:\nWH, MHG, BW und Wdh/Sätze beim BW"
            }
            Label {
                objectName: "comparison"
                visible: editor.comparison !== ""
                Layout.fillWidth: true
                text: editor.comparison
                elide: Text.ElideRight
                font.pixelSize: 11
                color: Styles.TokenInterface.semantics.text_muted
                HoverHandler { id: comparisonHover }
                ToolTip.visible: comparisonHover.hovered && truncated
                ToolTip.text: editor.comparison
            }
            Item { Layout.fillWidth: !parent.children[1].visible }
        }

        // General exercise as text
        RowLayout {
            spacing: 8
            visible: editor.kind === 1
            Layout.fillWidth: true
            Label { text: "Text:" }
            TextField {
                id: exerciseTextField
                objectName: "exerciseText"
                Layout.fillWidth: true
                text: editor.entryText
                placeholderText: "z.B. 4x12"
                onTextEdited: editor.takeText(text)
                Keys.onPressed: (event) => textSuggestions.handleKey(event)
                SuggestionPopup {
                    id: textSuggestions
                    field: exerciseTextField
                    suggestions: editor.kind === 1 && editor.exercise > 0
                                 ? Store.recentTexts(editor.athleteId, 1, editor.exercise) : []
                    onChosen: (item) => {
                        exerciseTextField.text = item.text
                        editor.takeText(item.text, item.totalReps)
                    }
                }
            }
            Label { text: "WH (ges.):" }
            TextField {
                id: repsField
                objectName: "totalReps"
                implicitWidth: 50
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator { bottom: 0; top: 9999 }
                text: editor.totalReps > 0 ? editor.totalReps : ""
                onTextEdited: {
                    // Emptied, it follows the text again
                    editor.repsTyped = text !== ""
                    editor.totalReps = parseInt(text) || editor.repsFromText(editor.entryText)
                    editor.changed()
                }
                ToolTip.visible: activeFocus
                ToolTip.text: "Aus dem Text, z.B. 4x12 = 48; von Hand überschreibbar"
            }
        }

        // Free text
        TextField {
            id: freeTextField
            objectName: "freeText"
            visible: editor.kind === 2
            Layout.fillWidth: true
            text: editor.entryText
            placeholderText: "z.B. Athletik 30 min."
            onTextEdited: { editor.entryText = text; editor.changed() }
            Keys.onPressed: (event) => noteSuggestions.handleKey(event)
            SuggestionPopup {
                id: noteSuggestions
                field: freeTextField
                suggestions: editor.kind === 2 ? Store.recentTexts(editor.athleteId, 2, 0) : []
                onChosen: (item) => {
                    freeTextField.text = item.text
                    editor.entryText = item.text
                    editor.changed()
                }
            }
        }
    }
}
