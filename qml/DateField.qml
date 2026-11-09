import QtQuick
import QtQuick.Controls
import Trainingsplaner

// A date: typed as TT.MM.JJJJ or picked in a calendar from the button in
// the field. Picking counts as an edit (textEdited), like typing.
TextField {
    id: field

    placeholderText: "TT.MM.JJJJ"
    implicitWidth: 136
    rightPadding: calendarButton.width + 4

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
