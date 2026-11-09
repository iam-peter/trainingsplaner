import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A month calendar with week numbers; picking a day or a week number
// picks that week. The chosen week and the one under the pointer are bands
// across the week number and the days.
Popup {
    id: popup

    property string monday            // the current week, "yyyy-MM-dd"
    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    signal picked(string monday)

    // The Monday of the week under the pointer, "" for none
    property string hovered: ""

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

    // The Monday of a row of the month grid: the grid starts with the week
    // of the 1st
    function rowMonday(row) {
        const d = new Date(year, month, 1, 12)
        d.setDate(d.getDate() - (d.getDay() + 6) % 7 + 7 * row)
        return d.toISOString().slice(0, 10)
    }

    function pick(m) {
        picked(m)
        close()
    }

    function bandColor(m) {
        return m === monday ? Theme.sh.pickerChosen : m === hovered ? Theme.sh.pickerHover : "transparent"
    }

    onClosed: hovered = ""

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
            // The week number and its days make one band
            columnSpacing: 0
            Item {}
            DayOfWeekRow {
                locale: Qt.locale("de_DE")
                Layout.fillWidth: true
                // Over the day columns, which have no padding either
                padding: 0
            }
            WeekNumberColumn {
                month: popup.month
                year: popup.year
                locale: Qt.locale("de_DE")
                Layout.fillHeight: true
                // Rows as high as the days', without gaps, so the numbers
                // stay on their weeks' lines; no padding, so the band runs
                // on into the days
                spacing: 0
                padding: 0
                // The style sets the sides on their own
                leftPadding: 0
                rightPadding: 0
                Layout.preferredWidth: 28
                delegate: Label {
                    required property int weekNumber
                    required property int index
                    readonly property string week: popup.rowMonday(index)
                    objectName: "week" + weekNumber
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: weekNumber
                    font.bold: true
                    // The band's left end
                    background: Rectangle {
                        color: popup.bandColor(week)
                        topLeftRadius: Theme.radius(4)
                        bottomLeftRadius: Theme.radius(4)
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) popup.hovered = week
                                          else if (popup.hovered === week) popup.hovered = ""
                    }
                    TapHandler { onTapped: popup.pick(week) }
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
                padding: 0
                delegate: Label {
                    required property var model
                    required property int index
                    readonly property string week: popup.mondayOf(model.date)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: model.month === popup.month ? 1 : 0.4
                    text: model.day
                    font.bold: model.today
                    color: palette.text
                    // The band, its right end at Sunday
                    background: Rectangle {
                        color: popup.bandColor(week)
                        topRightRadius: index % 7 === 6 ? Theme.radius(4) : 0
                        bottomRightRadius: topRightRadius
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) popup.hovered = week
                                          else if (popup.hovered === week) popup.hovered = ""
                    }
                }
                onClicked: (date) => popup.pick(popup.mondayOf(date))
            }
        }
    }
}
