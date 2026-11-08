import QtQuick
import Trainingsplaner
import QtQuick.Controls

// One competition attempt. Space toggles valid/invalid, as in the old
// program; an invalid attempt is red and struck through and stored negative.
TextField {
    id: field

    property int value: 0 // > 0 valid, < 0 invalid, 0 none
    signal edited()

    function setValue(v) {
        value = v
        text = v !== 0 ? String(Math.abs(v)) : ""
    }

    readonly property bool invalid: value < 0

    implicitWidth: 56
    horizontalAlignment: TextInput.AlignHCenter
    validator: IntValidator { bottom: 0; top: 999 }
    font.bold: true
    font.strikeout: invalid
    color: invalid ? Theme.error : palette.text

    onTextEdited: {
        const kg = parseInt(text) || 0
        value = invalid ? -kg : kg
        edited()
    }
    Keys.onSpacePressed: (event) => {
        if (value !== 0) {
            value = -value
            edited()
        }
        event.accepted = true
    }

    ToolTip.visible: activeFocus
    ToolTip.text: "Leertaste: gültig/ungültig"
    ToolTip.delay: 800
}
