import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A month calendar with week numbers; picking a day picks its week.
Popup {
    id: popup

    property string monday            // the current week, "yyyy-MM-dd"
    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    signal picked(string monday)

    onAboutToShow: {
        const d = new Date(monday + "T12:00:00")
        month = d.getMonth()
        year = d.getFullYear()
    }

    function shift(n) {
        let m = month + n, y = year
        while (m < 0) { m += 12; y-- }
        while (m > 11) { m -= 12; y++ }
        month = m
        year = y
    }

    function mondayOf(date) {
        const d = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12)
        d.setDate(d.getDate() - (d.getDay() + 6) % 7)
        return d.toISOString().slice(0, 10)
    }

    padding: 8
    contentItem: ColumnLayout {
        spacing: 4
        RowLayout {
            IconToolButton { iconName: "chevron-left"; onClicked: popup.shift(-1) }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale("de_DE").standaloneMonthName(popup.month) + " " + popup.year
                font.bold: true
            }
            IconToolButton { iconName: "chevron-right"; onClicked: popup.shift(1) }
        }
        GridLayout {
            columns: 2
            Item {}
            DayOfWeekRow {
                locale: Qt.locale("de_DE")
                Layout.fillWidth: true
            }
            WeekNumberColumn {
                month: popup.month
                year: popup.year
                locale: Qt.locale("de_DE")
                Layout.fillHeight: true
                // Rows as high as the days', without gaps, so the numbers
                // stay on their weeks' lines
                spacing: 0
                Layout.preferredWidth: 28
                delegate: Label {
                    required property int weekNumber
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: weekNumber
                    font.bold: true
                }
            }
            MonthGrid {
                id: grid
                month: popup.month
                year: popup.year
                locale: Qt.locale("de_DE")
                Layout.fillWidth: true
                implicitWidth: 260
                // Six rows of 28 px
                implicitHeight: 168
                // No gaps: the chosen week is one band across its days
                spacing: 0
                delegate: Label {
                    required property var model
                    required property int index
                    readonly property bool inWeek: popup.mondayOf(model.date) === popup.monday
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: model.month === popup.month ? 1 : 0.4
                    text: model.day
                    font.bold: model.today
                    color: palette.text
                    // A light band, rounded at Monday and Sunday only
                    background: Rectangle {
                        color: inWeek ? Theme.sh.accent : "transparent"
                        topLeftRadius: index % 7 === 0 ? Theme.radius(4) : 0
                        bottomLeftRadius: topLeftRadius
                        topRightRadius: index % 7 === 6 ? Theme.radius(4) : 0
                        bottomRightRadius: topRightRadius
                    }
                }
                onClicked: (date) => { popup.picked(popup.mondayOf(date)); popup.close() }
            }
        }
    }
}
