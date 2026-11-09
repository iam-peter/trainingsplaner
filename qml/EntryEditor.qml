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
    property string entryText: ""
    property int totalReps: 0
    property int combination: 0
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
    }

    // The same 12 px on every side: the icon buttons on the right are
    // pulled out by the free space around their icons (8 px), so the icons
    // end 12 px from the border like the fields on the left
    padding: 12
    background: Rectangle {
        color: palette.window
        border.color: palette.mid
        radius: Theme.radius(4)
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
                    color: text === "" || editor.exerciseValid ? palette.text : Theme.error
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
                color: editor.exercise !== 0 && !editor.exerciseValid ? Theme.error : palette.placeholderText
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
