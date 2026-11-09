import QtQuick
import Trainingsplaner
import QtQuick.Controls

// One competition attempt (kg). A failed attempt is marked invalid: red
// and struck through, stored negative. Space toggles it, as in the old
// program, and so does a right click.
TextField {
    id: field

    property int value: 0 // > 0 valid, < 0 invalid, 0 none
    signal edited()

    function toggle() {
        if (value !== 0) {
            value = -value
            edited()
        }
    }

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
        toggle()
        event.accepted = true
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: field.toggle()
    }

    ToolTip.visible: activeFocus || hovered
    ToolTip.text: invalid ? "Ungültiger Versuch. Leertaste oder Rechtsklick: wieder gültig"
                          : "Fehlversuch? Leertaste oder Rechtsklick: als ungültig markieren"
    ToolTip.delay: 800
}
