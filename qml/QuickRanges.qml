import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Quick ranges up to this week, as IDA offers them: the last 1, 2 or 4
// weeks, or the weeks of the last 1, 3 or 6 months. A click tells the
// first week's label ("33/2026") and the number of weeks; the range
// shown at the moment is marked.
RowLayout {
    id: ranges

    // The range in the fields, to mark the matching button
    property string fromLabel
    property int weeks: 0
    // Charts need two weeks at least
    property int minimumWeeks: 1

    signal picked(string fromLabel, int weeks)

    spacing: 4

    readonly property string thisMonday: Store.mondayOf(Store.today())

    function weeksBack(n) {
        return { from: Store.weekLabel(Store.addWeeks(thisMonday, -(n - 1))), weeks: n }
    }
    // From the week a month count back from today, to this week
    function monthsBack(n) {
        const d = new Date(Store.today() + "T12:00:00")
        d.setMonth(d.getMonth() - n)
        const iso = d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-"
                    + String(d.getDate()).padStart(2, "0")
        const from = Store.mondayOf(iso)
        const weeks = Math.round((new Date(thisMonday + "T12:00:00") - new Date(from + "T12:00:00")) / (7 * 86400000)) + 1
        return { from: Store.weekLabel(from), weeks: weeks }
    }
    function pick(r) {
        const weeks = Math.max(minimumWeeks, r.weeks)
        picked(weeks > r.weeks ? weeksBack(weeks).from : r.from, weeks)
    }

    Label { text: "Wochen"; color: Styles.TokenInterface.semantics.text_muted }
    Repeater {
        model: [1, 2, 4]
        Button {
            required property int modelData
            readonly property var range: ranges.weeksBack(Math.max(ranges.minimumWeeks, modelData))
            objectName: "weeks" + modelData
            text: modelData
            flat: !checked
            checkable: false
            checked: ranges.fromLabel === range.from && ranges.weeks === range.weeks
            implicitWidth: 30
            ToolTip.visible: hovered
            ToolTip.text: modelData === 1 ? "Diese Woche" : "Die letzten " + modelData + " Wochen, bis diese Woche"
            onClicked: ranges.pick(ranges.weeksBack(modelData))
        }
    }
    Item { implicitWidth: 6 }
    Label { text: "Monate"; color: Styles.TokenInterface.semantics.text_muted }
    Repeater {
        model: [1, 3, 6]
        Button {
            required property int modelData
            readonly property var range: ranges.monthsBack(modelData)
            objectName: "months" + modelData
            text: modelData
            flat: !checked
            checkable: false
            checked: ranges.fromLabel === range.from && ranges.weeks === range.weeks
            implicitWidth: 30
            ToolTip.visible: hovered
            ToolTip.text: (modelData === 1 ? "Der letzte Monat" : "Die letzten " + modelData + " Monate")
                          + ", " + range.weeks + " Wochen bis diese Woche"
            onClicked: ranges.pick(ranges.monthsBack(modelData))
        }
    }
}
