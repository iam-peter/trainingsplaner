import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A date: typed as TT.MM.JJJJ or picked in a calendar from the button in
// the field. Picking counts as an edit (textEdited), like typing.
TextField {
    id: field

    placeholderText: "TT.MM.JJJJ"
    implicitWidth: 136

    trailingItems: FieldButton {
        id: calendarButton
        objectName: "calendarButton"
        iconName: "calendar-days"
        toolTip: "Im Kalender wählen"
        enabled: !field.readOnly && field.enabled
        onClicked: calendar.open()
    }

    DateCalendar {
        id: calendar
        objectName: "dateCalendar"
        y: field.height + 4
        date: Store.parseDate(field.text)
        onPicked: (d) => {
            field.text = Store.formatDate(d)
            field.textEdited()
            field.forceActiveFocus()
        }
    }
}
