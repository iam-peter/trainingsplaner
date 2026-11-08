import QtQuick
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

    property int kind: 0            // 0 weights, 1 exercise text, 2 free text
    property int exercise: 0
    property var steps: []
    property string entryText: ""
    property int totalReps: 0
    property int combination: 0
    property var entryStats: ({})

    signal changed()
    signal removeRequested()
    signal moveRequested(int delta)

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
            steps: steps.filter(s => s && (s.kg > 0 || s.reps > 0 || s.sets > 0)),
            text: entryText,
            totalReps: totalReps,
            combination: combination
        }
    }

    function focusFirst() {
        if (kind === 2)
            freeTextField.forceActiveFocus()
        else
            numberField.forceActiveFocus()
    }

    function updateStats() {
        entryStats = Store.stats(steps)
    }

    function setStep(index, key, val) {
        while (steps.length <= index)
            steps.push({ kg: 0, reps: 0, sets: 0, failed: 0 })
        steps[index][key] = val
        if (index === stepModel.count - 1 && val > 0)
            stepModel.append({})
        updateStats()
        changed()
    }

    function stepValue(index, key) {
        const s = steps[index]
        return s && s[key] > 0 ? String(s[key]) : ""
    }

    ListModel { id: stepModel }

    Component.onCompleted: {
        kind = source.kind || 0
        exercise = source.exercise || 0
        steps = (source.steps || []).map(s => ({ kg: s.kg, reps: s.reps, sets: s.sets, failed: s.failed }))
        entryText = source.text || ""
        totalReps = source.totalReps || 0
        combination = source.combination || 0
        for (let i = 0; i <= steps.length; ++i)
            stepModel.append({})
        updateStats()
    }

    padding: 6
    background: Rectangle {
        color: palette.window
        border.color: palette.mid
        radius: 4
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

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
                    color: text === "" || editor.exerciseValid ? palette.text : "#c00000"
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
                color: editor.exercise !== 0 && !editor.exerciseValid ? "#c00000" : palette.placeholderText
            }
            ExercisePicker {
                id: picker
                y: numberField.height + 2
                textExercises: editor.kind === 1
                current: editor.exercise
                onPicked: (id) => {
                    editor.exercise = id
                    editor.changed()
                    if (editor.kind === 0 && stepRepeater.count > 0)
                        stepRepeater.itemAt(0).focusKg()
                    else if (editor.kind === 1)
                        exerciseTextField.forceActiveFocus()
                }
            }
        }

        // Weight steps
        ColumnLayout {
            visible: editor.kind === 0
            spacing: 2
            Layout.alignment: Qt.AlignTop
            Label { text: "KG:"; font.pixelSize: 11; Layout.preferredHeight: 30; verticalAlignment: Text.AlignVCenter }
            Label { text: editor.actual ? "SG/ANZ/UG:" : "SG/ANZ:"; font.pixelSize: 11; Layout.preferredHeight: 26; verticalAlignment: Text.AlignVCenter }
        }
        Flow {
            visible: editor.kind === 0
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                id: stepRepeater
                model: stepModel
                ColumnLayout {
                    id: stepItem
                    required property int index
                    spacing: 2
                    function focusKg() { kgField.forceActiveFocus() }

                    TextField {
                        id: kgField
                        objectName: "kg" + stepItem.index
                        Layout.preferredWidth: editor.actual ? 82 : 57
                        implicitHeight: 30
                        horizontalAlignment: TextInput.AlignHCenter
                        font.bold: true
                        font.pixelSize: 15
                        validator: IntValidator { bottom: 0; top: 999 }
                        text: editor.stepValue(stepItem.index, "kg")
                        onTextEdited: editor.setStep(stepItem.index, "kg", parseInt(text) || 0)
                    }
                    RowLayout {
                        spacing: 1
                        TextField {
                            implicitWidth: 28
                            implicitHeight: 26
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 999 }
                            objectName: "reps" + stepItem.index
                            text: editor.stepValue(stepItem.index, "reps")
                            onTextEdited: editor.setStep(stepItem.index, "reps", parseInt(text) || 0)
                            ToolTip.visible: activeFocus
                            ToolTip.text: "SG: Wiederholungen pro Satz"
                        }
                        TextField {
                            implicitWidth: 28
                            implicitHeight: 26
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 99 }
                            objectName: "sets" + stepItem.index
                            text: editor.stepValue(stepItem.index, "sets")
                            placeholderText: "1"
                            onTextEdited: editor.setStep(stepItem.index, "sets", parseInt(text) || 0)
                            ToolTip.visible: activeFocus
                            ToolTip.text: "ANZ: Anzahl Sätze"
                        }
                        TextField {
                            visible: editor.actual
                            implicitWidth: 24
                            implicitHeight: 26
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 9 }
                            text: editor.stepValue(stepItem.index, "failed")
                            onTextEdited: editor.setStep(stepItem.index, "failed", parseInt(text) || 0)
                            ToolTip.visible: activeFocus
                            ToolTip.text: "UG: ungültige Versuche"
                        }
                    }
                }
            }
        }

        // General exercise as text
        RowLayout {
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
                onTextEdited: { editor.entryText = text; editor.changed() }
            }
            Label { text: "WH (ges.):" }
            TextField {
                implicitWidth: 50
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator { bottom: 0; top: 9999 }
                text: editor.totalReps > 0 ? editor.totalReps : ""
                onTextEdited: { editor.totalReps = parseInt(text) || 0; editor.changed() }
            }
        }

        // Free text
        RowLayout {
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
            spacing: 0
            RowLayout {
                spacing: 0
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
