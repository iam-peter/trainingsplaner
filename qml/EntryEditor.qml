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

    // The same 12 px on every side: the icon buttons on the right are
    // pulled out by the free space around their icons (8 px), so the icons
    // end 12 px from the border like the fields on the left
    padding: 12
    background: Rectangle {
        color: Styles.TokenInterface.semantics.background_default
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        radius: Styles.Primitives.radius.r4
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Exercise number with picker
        ColumnLayout {
            visible: editor.kind !== 2
            spacing: 2
            Layout.alignment: Qt.AlignTop
            RowLayout {
                spacing: 2
                TextField {
                    id: numberField
                    objectName: "exerciseField"
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
                }
                IconButton {
                    implicitWidth: 30
                    implicitHeight: numberField.height
                    iconName: "layout-grid"
                    toolTip: "Übung auswählen"
                    onClicked: picker.open()
                }
            }
            Label {
                Layout.preferredWidth: 150
                text: editor.exercise === 0 ? (editor.kind === 1 ? "AMKT-Übung" : "Übung")
                      : editor.exerciseValid ? editor.exerciseInfo.name
                      : editor.exerciseInfo ? "Nr. nicht für " + (editor.kind === 1 ? "Text" : "Gewichte")
                      : "unbekannte Nr."
                elide: Text.ElideRight
                font.pixelSize: 11
                color: editor.exercise !== 0 && !editor.exerciseValid ? Styles.TokenInterface.semantics.danger_default : Styles.TokenInterface.semantics.text_muted
            }
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

        // Weight steps
        StepsEditor {
            id: stepsEditor
            visible: editor.kind === 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            initialSteps: editor.source.steps || []
            actual: editor.actual
            jump: editor.kind === 0 && editor.exercise > 0 ? Store.usualJump(editor.athleteId, editor.monday, editor.exercise) : 5
            suggestions: editor.kind === 0 && editor.exercise > 0 ? Store.recentSteps(editor.athleteId, editor.exercise) : []
            onChanged: editor.changed()
        }

        // General exercise as text
        RowLayout {
            spacing: 8
            visible: editor.kind === 1
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
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
        RowLayout {
            spacing: 8
            visible: editor.kind === 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Label { text: "Text:" }
            TextField {
                id: freeTextField
                objectName: "freeText"
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

        // Figures: this session (week)
        GridLayout {
            visible: editor.kind === 0
            Layout.alignment: Qt.AlignTop
            columns: 2
            columnSpacing: 16
            rowSpacing: 4
            Label {
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: (editor.entryStats.mhg || 0) + " (" + (editor.week ? editor.week.mhg : 0) + ")"
            }
            Label {
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: (editor.entryStats.bw || 0) + " (" + (editor.week ? editor.week.bw : 0) + ")"
            }
            Label {
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: (editor.entryStats.wh || 0) + " (" + (editor.week ? editor.week.wh : 0) + ")"
            }
            Label {
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: (editor.entryStats.repsSets || "–") + " (" + (editor.week ? editor.week.repsSets : "–") + ")"
            }
        }

        // Move / remove
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.rightMargin: -8
            spacing: 0
            RowLayout {
                spacing: 0
                IconToolButton {
                    visible: editor.kind === 0
                    enabled: editor.exerciseValid
                    iconName: "list"
                    toolTip: "Info: frühere Einheiten dieser Übung"
                    onClicked: editor.infoRequested(editor.exercise, false)
                }
                IconToolButton {
                    visible: editor.kind === 0
                    enabled: editor.exerciseValid
                    iconName: "chart-line"
                    toolTip: "Grafik der letzten Wochen"
                    onClicked: editor.infoRequested(editor.exercise, true)
                }
                IconToolButton {
                    iconName: "arrow-up"
                    toolTip: "Nach oben"
                    enabled: editor.canMoveUp
                    onClicked: editor.moveRequested(-1)
                }
                IconToolButton {
                    iconName: "arrow-down"
                    toolTip: "Nach unten"
                    enabled: editor.canMoveDown
                    onClicked: editor.moveRequested(1)
                }
                IconToolButton {
                    iconName: "trash-2"
                    toolTip: "Zeile entfernen"
                    onClicked: editor.removeRequested()
                }
            }
        }
    }
}
