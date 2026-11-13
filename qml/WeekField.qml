import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A calendar week: typed as WW/JJJJ (46/2026) or picked in the week
// calendar from the button in the field, like DateField and TimeField.
// Picking counts as an edit (textEdited) and also tells the week's Monday
// (weekPicked).
TextField {
    id: field

    signal weekPicked(string monday)
    // For a linked pair of fields (RangeLink): an edit starts when the
    // field gets the focus or its calendar opens, and is done when the
    // field is left or a week picked
    signal editStarted()
    signal editDone()

    onActiveFocusChanged: if (activeFocus) editStarted()
    onEditingFinished: editDone()

    // The week's Monday, "" while the text is no week
    readonly property string monday: Store.weekFromLabel(text)

    placeholderText: "WW/JJJJ"
    // Room for the widest week and the calendar beside the style's padding
    implicitWidth: Math.ceil(digits.advanceWidth) + leftPadding + rightPadding + 8

    TextMetrics {
        id: digits
        font: field.font
        text: "53/2026"
    }

    trailingItems: FieldButton {
        id: calendarButton
        objectName: "calendarButton"
        iconName: "calendar-days"
        toolTip: "Woche im Kalender wählen"
        enabled: !field.readOnly && field.enabled
        onClicked: {
            field.editStarted()
            calendar.open()
        }
    }

    WeekCalendar {
        id: calendar
        objectName: "weekCalendar"
        y: field.height + 4
        // The typed week, else this one
        monday: field.monday !== "" ? field.monday : Store.mondayOf(Store.today())
        onPicked: (m) => {
            field.text = Store.weekLabel(m)
            field.textEdited()
            field.weekPicked(m)
            field.editDone()
            field.forceActiveFocus()
        }
    }
}
