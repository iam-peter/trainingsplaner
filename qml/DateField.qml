import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A date: typed as TT.MM.JJJJ or picked in a calendar from the button in
// the field. Picking counts as an edit (textEdited), like typing.
TextField {
    id: field

    // For a linked pair of fields (RangeLink): an edit starts when the
    // field gets the focus or its calendar opens, and is done when the
    // field is left or a date picked
    signal editStarted()
    signal editDone()

    onActiveFocusChanged: if (activeFocus) editStarted()
    onEditingFinished: editDone()

    placeholderText: "TT.MM.JJJJ"
    implicitWidth: 136

    trailingItems: FieldButton {
        id: calendarButton
        objectName: "calendarButton"
        iconName: "calendar-days"
        toolTip: "Im Kalender wählen"
        enabled: !field.readOnly && field.enabled
        onClicked: {
            field.editStarted()
            calendar.open()
        }
    }

    DateCalendar {
        id: calendar
        objectName: "dateCalendar"
        y: field.height + 4
        date: Store.parseDate(field.text)
        onPicked: (d) => {
            field.text = Store.formatDate(d)
            field.textEdited()
            field.editDone()
            field.forceActiveFocus()
        }
    }
}
