import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner
import TrainingsplanerStyle as Styles

// Weight steps of one exercise: kg on top, reps per set (SG) and sets (ANZ)
// below, failed attempts (UG) in actual weeks. There is always one empty
// step at the end; typing into it adds the next.
RowLayout {
    id: root

    property var initialSteps: []   // read once
    property bool actual: false
    property var steps: []
    property var stats: ({})
    // What the athlete usually adds from one step to the next (Store.usualJump)
    property int jump: 5
    // Steps whose kg were proposed, not typed: they follow the step before
    property var proposed: []
    // The athlete's earlier steps of this exercise (Store.recentSteps),
    // offered under the first weight while the line has no reps yet
    property var suggestions: []
    readonly property bool fresh: (stats, !steps.some(s => s && s.reps > 0))

    // An earlier line taken whole; the focus goes to the empty step after it
    function takeSuggestion(list) {
        setSteps(list)
        const last = stepRepeater.itemAt(stepRepeater.count - 1)
        if (last)
            last.focusKg()
    }

    signal changed()

    // A weight typed into a step proposes the next one, weight + jump, as
    // long as that one was not typed itself; clearing it takes it back
    function propose(index) {
        const next = index + 1
        const isProposed = proposed.indexOf(next) >= 0
        // A weight typed there stays
        if (steps[next] && steps[next].kg > 0 && !isProposed)
            return
        const kg = steps[index] && steps[index].kg > 0 ? Math.min(999, steps[index].kg + jump) : 0
        // Nothing to propose, and nothing proposed to take back
        if (kg === 0 && !isProposed)
            return
        proposed = kg > 0 ? proposed.filter(i => i !== next).concat([next]) : proposed.filter(i => i !== next)
        setStep(next, "kg", kg)
        const item = stepRepeater.itemAt(next)
        if (item)
            item.showKg()
    }

    // ↑ / ↓ in reps, sets or UG: one more or less, between empty and max
    function bump(field, index, key, delta, max) {
        const v = Math.max(0, Math.min(max, (parseInt(field.text) || 0) + delta))
        field.text = v > 0 ? String(v) : ""
        typed(index)
        setStep(index, key, v)
    }

    // The step's kg typed by hand: no longer a proposal
    function typed(index) {
        if (proposed.indexOf(index) >= 0)
            proposed = proposed.filter(i => i !== index)
    }

    function value() {
        // A proposed weight nobody took up is no step
        return steps.filter((s, i) => s && (s.kg > 0 || s.reps > 0 || s.sets > 0) && proposed.indexOf(i) < 0)
    }

    // Replaces all steps (pasting copied steps)
    function setSteps(list) {
        steps = (list || []).map(s => ({ kg: s.kg, reps: s.reps, sets: s.sets, failed: s.failed || 0 }))
        proposed = []
        stepModel.clear()
        for (let i = 0; i <= steps.length; ++i)
            stepModel.append({})
        updateStats()
        changed()
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

    spacing: 8

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
                function showKg() { kgField.text = root.stepValue(stepItem.index, "kg") }

                TextField {
                    id: kgField
                    objectName: "kg" + stepItem.index
                    Layout.preferredWidth: root.actual ? 82 : 57
                    implicitHeight: 30
                    horizontalAlignment: TextInput.AlignHCenter
                    font.bold: true
                    font.pixelSize: 15
                    // A proposed weight is grey until it is typed over or
                    // the step gets its reps; entering the field selects it,
                    // so typing replaces it
                    color: root.proposed.indexOf(stepItem.index) >= 0
                           ? Styles.TokenInterface.semantics.text_muted : Styles.TokenInterface.semantics.text_default
                    onActiveFocusChanged: if (activeFocus && root.proposed.indexOf(stepItem.index) >= 0) selectAll()
                    validator: IntValidator { bottom: 0; top: 999 }
                    text: root.stepValue(stepItem.index, "kg")
                    onTextEdited: {
                        root.typed(stepItem.index)
                        root.setStep(stepItem.index, "kg", parseInt(text) || 0)
                        root.propose(stepItem.index)
                    }
                    // Arrow keys: next weight by the step from the settings,
                    // or through the earlier lines when they are offered
                    Keys.onUpPressed: (event) => {
                        if (stepSuggestions.item && stepSuggestions.item.visible)
                            stepSuggestions.item.handleKey(event)
                        else
                            stepBy(1)
                    }
                    Keys.onDownPressed: (event) => {
                        if (stepSuggestions.item && stepSuggestions.item.visible)
                            stepSuggestions.item.handleKey(event)
                        else
                            stepBy(-1)
                    }
                    Keys.onPressed: (event) => { if (stepSuggestions.item) stepSuggestions.item.handleKey(event) }
                    Loader {
                        id: stepSuggestions
                        active: stepItem.index === 0 && root.suggestions.length > 0
                        sourceComponent: SuggestionPopup {
                            field: kgField
                            prefix: true
                            active: root.fresh
                            suggestions: root.suggestions
                            // Replacing the steps removes this field, so later
                            onChosen: (item) => Qt.callLater(root.takeSuggestion, item.steps)
                        }
                    }
                    function stepBy(direction) {
                        const kg = Store.stepWeight(parseInt(text) || 0, direction)
                        text = kg > 0 ? String(kg) : ""
                        root.typed(stepItem.index)
                        root.setStep(stepItem.index, "kg", kg)
                        root.propose(stepItem.index)
                    }
                }
                RowLayout {
                    spacing: 1
                    TextField {
                        id: repsField
                        objectName: "reps" + stepItem.index
                        implicitWidth: 28
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 999 }
                        text: root.stepValue(stepItem.index, "reps")
                        // Reps for a proposed weight take it as it is
                        onTextEdited: {
                            root.typed(stepItem.index)
                            root.setStep(stepItem.index, "reps", parseInt(text) || 0)
                        }
                        Keys.onUpPressed: root.bump(repsField, stepItem.index, "reps", 1, 999)
                        Keys.onDownPressed: root.bump(repsField, stepItem.index, "reps", -1, 999)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "SG: Wiederholungen pro Satz (↑ / ↓)"
                    }
                    TextField {
                        id: setsField
                        objectName: "sets" + stepItem.index
                        implicitWidth: 28
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 99 }
                        text: root.stepValue(stepItem.index, "sets")
                        onTextEdited: root.setStep(stepItem.index, "sets", parseInt(text) || 0)
                        Keys.onUpPressed: root.bump(setsField, stepItem.index, "sets", 1, 99)
                        Keys.onDownPressed: root.bump(setsField, stepItem.index, "sets", -1, 99)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "ANZ: Anzahl Sätze, leer: 1 Satz (↑ / ↓)"
                    }
                    TextField {
                        id: failedField
                        objectName: "failed" + stepItem.index
                        visible: root.actual
                        implicitWidth: 24
                        implicitHeight: 26
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 0; top: 9 }
                        text: root.stepValue(stepItem.index, "failed")
                        onTextEdited: root.setStep(stepItem.index, "failed", parseInt(text) || 0)
                        Keys.onUpPressed: root.bump(failedField, stepItem.index, "failed", 1, 9)
                        Keys.onDownPressed: root.bump(failedField, stepItem.index, "failed", -1, 9)
                        ToolTip.visible: activeFocus
                        ToolTip.text: "UG: ungültige Versuche (↑ / ↓)"
                    }
                }
            }
        }
    }
}
