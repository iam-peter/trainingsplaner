import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Weight steps of one exercise: kg on top, reps per set (SG) and sets (ANZ)
// below, failed attempts (UG) in actual weeks. There is always one empty
// step at the end; typing into it adds the next.
RowLayout {
    id: root

    property var initialSteps: []   // read once
    property bool actual: false
    property var steps: []
    property var stats: ({})

    signal changed()

    function value() {
        return steps.filter(s => s && (s.kg > 0 || s.reps > 0 || s.sets > 0))
    }

    function focusFirst() {
        if (stepRepeater.count > 0)
            stepRepeater.itemAt(0).focusKg()
    }

    function updateStats() {
        stats = Store.stats(steps)
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
        steps = (initialSteps || []).map(s => ({ kg: s.kg, reps: s.reps, sets: s.sets, failed: s.failed }))
        for (let i = 0; i <= steps.length; ++i)
            stepModel.append({})
        updateStats()
    }

    spacing: 10

    ColumnLayout {
        spacing: 2
        Layout.alignment: Qt.AlignTop
        Label { text: "KG:"; font.pixelSize: 11; Layout.preferredHeight: 30; verticalAlignment: Text.AlignVCenter }
        Label { text: root.actual ? "SG/ANZ/UG:" : "SG/ANZ:"; font.pixelSize: 11; Layout.preferredHeight: 26; verticalAlignment: Text.AlignVCenter }
    }

    Flow {
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
                    Layout.preferredWidth: root.actual ? 82 : 57
                    implicitHeight: 30
                    horizontalAlignment: TextInput.AlignHCenter
                    font.bold: true
                    font.pixelSize: 15
                    validator: IntValidator { bottom: 0; top: 999 }
                    text: root.stepValue(stepItem.index, "kg")
                    onTextEdited: root.setStep(stepItem.index, "kg", parseInt(text) || 0)
                    // Arrow keys: next weight by the step from the settings
                    Keys.onUpPressed: stepBy(1)
                    Keys.onDownPressed: stepBy(-1)
                    function stepBy(direction) {
                        const kg = Store.stepWeight(parseInt(text) || 0, direction)
                        text = kg > 0 ? String(kg) : ""
                        root.setStep(stepItem.index, "kg", kg)
                    }
                }
                RowLayout {
                    spacing: 1
                    TextField {
                        objectName: "reps" + stepItem.index
                        implicitWidth: 28
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 999 }
                        text: root.stepValue(stepItem.index, "reps")
                        onTextEdited: root.setStep(stepItem.index, "reps", parseInt(text) || 0)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "SG: Wiederholungen pro Satz"
                    }
                    TextField {
                        objectName: "sets" + stepItem.index
                        implicitWidth: 28
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 99 }
                        text: root.stepValue(stepItem.index, "sets")
                        placeholderText: "1"
                        onTextEdited: root.setStep(stepItem.index, "sets", parseInt(text) || 0)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "ANZ: Anzahl Sätze"
                    }
                    TextField {
                        visible: root.actual
                        implicitWidth: 24
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 9 }
                        text: root.stepValue(stepItem.index, "failed")
                        onTextEdited: root.setStep(stepItem.index, "failed", parseInt(text) || 0)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "UG: ungültige Versuche"
                    }
                }
            }
        }
    }
}
