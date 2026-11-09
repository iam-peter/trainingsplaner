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

    // The week's Monday, "" while the text is no week
    readonly property string monday: Store.weekFromLabel(text)

    placeholderText: "WW/JJJJ"
    // Room for the widest week and the calendar beside the style's padding
    implicitWidth: Math.ceil(digits.advanceWidth) + leftPadding + rightPadding + 8
    rightPadding: calendarButton.width + 4

    TextMetrics {
        id: digits
        font: field.font
        text: "53/2026"
    }

    IconToolButton {
        id: calendarButton
        objectName: "calendarButton"
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 4
        width: height
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        iconName: "calendar-days"
        toolTip: "Woche im Kalender wählen"
        enabled: !field.readOnly && field.enabled
        onClicked: calendar.open()
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
            field.forceActiveFocus()
        }
    }
}
