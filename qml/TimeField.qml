import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A time of day as HH:MM: typed (8, 815, 8:5 and 08:15 all work and are
// written out when leaving the field) or picked from the clock button.
// Picking counts as an edit (textEdited), like typing; empty is allowed.
TextField {
    id: field

    placeholderText: "HH:MM"
    // Room for HH:MM and the clock beside the style's own padding
    implicitWidth: Math.ceil(digits.advanceWidth) + leftPadding + rightPadding + 8
    inputMethodHints: Qt.ImhPreferNumbers
    validator: RegularExpressionValidator { regularExpression: /^\d{0,2}(:\d{0,2})?$|^\d{3,4}$/ }

    // The time to save: written out even while the field still has the
    // focus (8 → 08:00); what is no time is kept, so saving can reject it
    readonly property string time: normalized(text) || text.trim()
    // Empty or a time of day; 25 or 9:75 are not
    readonly property bool valid: text.trim() === "" || normalized(text) !== ""

    // "08:15" from what was typed, "" when it is no time
    function normalized(t) {
        t = t.trim()
        if (t === "")
            return ""
        let h, m
        const parts = t.split(":")
        if (parts.length === 2) {
            h = parseInt(parts[0])
            m = parts[1] === "" ? 0 : parseInt(parts[1])
        } else if (t.length <= 2) {
            h = parseInt(t)
            m = 0
        } else {
            h = parseInt(t.slice(0, t.length - 2))
            m = parseInt(t.slice(-2))
        }
        if (isNaN(h) || isNaN(m) || h > 23 || m > 59)
            return ""
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    onEditingFinished: {
        const n = normalized(text)
        if (n !== "" && n !== text) {
            text = n
            textEdited()
        }
    }

    TextMetrics {
        id: digits
        font: field.font
        text: "HH:MM"
    }

    trailingItems: FieldButton {
        id: clockButton
        objectName: "clockButton"
        iconName: "clock"
        toolTip: "Uhrzeit wählen"
        enabled: !field.readOnly && field.enabled
        onClicked: {
            const n = field.normalized(field.text)
            picker.hour = n !== "" ? parseInt(n.slice(0, 2)) : -1
            picker.minute = n !== "" ? parseInt(n.slice(3)) : -1
            picker.open()
        }
    }

    TimePicker {
        id: picker
        objectName: "timePicker"
        y: field.height + 4
        onPicked: (h, m) => {
            field.text = picker.two(h) + ":" + picker.two(m)
            field.textEdited()
        }
        onCleared: {
            field.text = ""
            field.textEdited()
        }
    }
}
