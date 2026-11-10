import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// A month calendar to pick a day. Month and year can also be chosen
// directly, for dates far back such as a birthday.
Popup {
    id: popup

    property string date              // the chosen day, "yyyy-MM-dd", or ""
    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    signal picked(string date)

    onAboutToShow: {
        const d = new Date((date !== "" ? date : Store.today()) + "T12:00:00")
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

    function iso(d) {
        const p = n => (n < 10 ? "0" : "") + n
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
    }

    padding: 8
    contentItem: ColumnLayout {
        spacing: 4
        RowLayout {
            spacing: 4
            IconToolButton { iconName: "chevron-left"; toolTip: "Voriger Monat"; onClicked: popup.shift(-1) }
            ComboBox {
                Layout.fillWidth: true
                model: Array.from({ length: 12 }, (_, i) => Qt.locale("de_DE").standaloneMonthName(i))
                currentIndex: popup.month
                onActivated: (i) => popup.month = i
            }
            SpinBox {
                implicitWidth: 112
                from: 1900
                to: 2100
                editable: true
                value: popup.year
                // No thousands separator in a year
                textFromValue: (v) => String(v)
                valueFromText: (t) => parseInt(t) || popup.year
                onValueModified: popup.year = value
            }
            IconToolButton { iconName: "chevron-right"; toolTip: "Nächster Monat"; onClicked: popup.shift(1) }
        }
        DayOfWeekRow {
            locale: Qt.locale("de_DE")
            Layout.fillWidth: true
        }
        MonthGrid {
            month: popup.month
            year: popup.year
            locale: Qt.locale("de_DE")
            Layout.fillWidth: true
            implicitWidth: 280
            // Six rows of 28 px, like the week calendar
            implicitHeight: 6 * 28 + 5 * spacing
            delegate: Label {
                required property var model
                readonly property bool chosen: popup.iso(model.date) === popup.date
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: model.month === popup.month ? 1 : 0.4
                text: model.day
                font.bold: model.today
                color: Styles.TokenInterface.semantics.text_default
                // Chosen and under the pointer as in the other pickers
                background: Rectangle {
                    color: chosen ? Styles.TokenInterface.semantics.picker_chosen : dayHover.hovered ? Styles.TokenInterface.semantics.picker_hover : "transparent"
                    radius: Styles.Primitives.radius.r4
                }
                HoverHandler {
                    id: dayHover
                    cursorShape: Qt.PointingHandCursor
                }
            }
            onClicked: (d) => { popup.picked(popup.iso(d)); popup.close() }
        }
    }
}
