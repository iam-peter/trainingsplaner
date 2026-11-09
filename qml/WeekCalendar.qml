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

    // The grid's six weeks begin with the week of the 1st
    readonly property string firstMonday: mondayOf(new Date(year, month, 1, 12))

    // The date "yyyy-MM-dd" n days after the given one
    function addDays(iso, n) {
        const d = new Date(iso + "T12:00:00")
        d.setDate(d.getDate() + n)
        return d.toISOString().slice(0, 10)
    }

    // The ISO week number of a Monday (week 1 holds 4 January)
    function weekNumber(iso) {
        const d = new Date(iso + "T12:00:00")
        d.setDate(d.getDate() + 3)          // the Thursday decides the year
        const jan4 = new Date(d.getFullYear(), 0, 4, 12)
        return 1 + Math.round((d - jan4) / 86400000 / 7 + ((jan4.getDay() + 6) % 7 - 3) / 7)
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
        // Our own grid rather than Qt's DayOfWeekRow, WeekNumberColumn and
        // MonthGrid: they start and space their rows differently between Qt
        // versions, and the week numbers then missed their days. Each week
        // is one row, its number and seven days on one band.
        Column {
            spacing: 0
            Row {
                Item { width: 28; height: 24 }
                Repeater {
                    model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    Label {
                        required property string modelData
                        width: 37
                        height: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        font.bold: true
                    }
                }
            }
            Repeater {
                model: 6
                Item {
                    id: weekRow
                    required property int index
                    readonly property string week: popup.addDays(popup.firstMonday, 7 * index)
                    readonly property int number: popup.weekNumber(week)
                    objectName: "week" + number
                    width: 28 + 7 * 37
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius(4)
                        color: popup.bandColor(weekRow.week)
                    }
                    Row {
                        Label {
                            width: 28
                            height: 28
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: weekRow.number
                            font.bold: true
                        }
                        Repeater {
                            model: 7
                            Label {
                                required property int index
                                readonly property date day: new Date(popup.addDays(weekRow.week, index) + "T12:00:00")
                                width: 37
                                height: 28
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                opacity: day.getMonth() === popup.month ? 1 : 0.4
                                text: day.getDate()
                                font.bold: popup.addDays(weekRow.week, index) === Store.today()
                            }
                        }
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) popup.hovered = weekRow.week
                                          else if (popup.hovered === weekRow.week) popup.hovered = ""
                    }
                    TapHandler { onTapped: popup.pick(weekRow.week) }
                }
            }
        }
    }
}
