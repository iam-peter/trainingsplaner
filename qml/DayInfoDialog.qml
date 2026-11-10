import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Extra info per day (Zusatzinfo) for the days of one week: body weight,
// body fat, supplements ... Every entry is a row of fields, edited in
// place and saved together, as in Erfassung Kader; Abbrechen leaves the
// week as it was.
EditorDialog {
    id: dialog

    property string athleteId
    property string monday
    property string error
    // The week's days ("yyyy-MM-dd") and their names, for every row's box
    property var days: []
    property var dayNames: []

    // Shared by the headings and the rows; the category takes the rest
    readonly property int wDay: 150
    readonly property int wTime: 96
    readonly property int wValue: 104
    readonly property int wRemove: 32

    function edit(a, m) {
        athleteId = a
        monday = m
        error = ""
        const list = []
        const names = []
        for (let d = 1; d <= 7; ++d) {
            const date = new Date(monday + "T12:00:00")
            date.setDate(date.getDate() + d - 1)
            list.push(date.toISOString().slice(0, 10))
            names.push(Store.dayName(d) + ", " + Store.dayDate(monday, d))
        }
        days = list
        dayNames = names
        // The rows after opening, as in Erfassung Kader: rows changed
        // while the dialog is hidden keep the last opening's layout
        open()
        rows.clear()
        for (const e of Store.dayInfo(athleteId, monday))
            rows.append({ date: e.date, time: e.time, code: e.code, value: e.valueText })
        // Nothing entered yet: a row to start typing in
        if (rows.count === 0)
            addRow()
        dirty = false
    }

    function addRow() {
        // Today in this week, else its Monday; the category of the row above
        const today = days.indexOf(Store.today())
        const above = rows.count > 0 ? rows.get(rows.count - 1).code : ""
        const first = Store.infoCategories.length > 0 ? Store.infoCategories[0].code : ""
        rows.append({ date: days[Math.max(0, today)], time: "", code: above || first, value: "" })
        dirty = true
        Qt.callLater(() => { rowList.forceLayout(); rowList.positionViewAtEnd() })
    }

    function save() {
        const list = []
        // Plain objects: the model's own elements reach C++ as empty maps
        for (let i = 0; i < rows.count; ++i) {
            const r = rows.get(i)
            list.push({ date: r.date, time: r.time, code: r.code, value: r.value })
        }
        error = Store.saveWeekInfo(athleteId, monday, list)
        if (error !== "")
            return
        dirty = false
        close()
    }

    title: "Zusatzinfo  –  Woche " + Store.weekLabel(monday)
    width: parent ? Math.min(parent.width - 40, 700) : 700
    discardText: "Die Änderungen an der Zusatzinfo gehen verloren."

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.onTop
        onActivated: dialog.save()
    }

    ListModel { id: rows }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.rightMargin: dialog.wRemove + 8 + rowBar.room
            Label { text: "Tag"; Layout.preferredWidth: dialog.wDay; font.bold: true }
            Label { text: "Zeit"; Layout.preferredWidth: dialog.wTime; font.bold: true }
            Label { text: "Kategorie"; Layout.fillWidth: true; font.bold: true }
            Label { text: "Wert"; Layout.preferredWidth: dialog.wValue; font.bold: true }
        }

        // As high as its rows, until the dialog reaches the window's height;
        // then it scrolls
        ListView {
            id: rowList
            objectName: "rowList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Math.min(contentHeight, 80)
            clip: true
            // The fields' borders sit on the edge: without a pixel around,
            // the clip cut the first row's top line
            topMargin: 1
            bottomMargin: 1
            Layout.preferredHeight: contentHeight + topMargin + bottomMargin
            boundsBehavior: Flickable.StopAtBounds
            spacing: 8
            model: rows
            ScrollBar.vertical: AppScrollBar { id: rowBar }
            delegate: RowLayout {
                id: row
                objectName: "infoRow"
                required property int index
                required property string date
                required property string time
                required property string code
                required property string value
                readonly property var category: Store.infoCategories.find(c => c.code === code) ?? null
                width: ListView.view.width - rowBar.room
                spacing: 8
                ComboBox {
                    objectName: "dayBox"
                    Layout.preferredWidth: dialog.wDay
                    model: dialog.dayNames
                    currentIndex: dialog.days.indexOf(row.date)
                    onActivated: { rows.setProperty(row.index, "date", dialog.days[currentIndex]); dialog.dirty = true }
                }
                TimeField {
                    objectName: "timeField"
                    Layout.preferredWidth: dialog.wTime
                    text: row.time
                    onTextEdited: { rows.setProperty(row.index, "time", time); dialog.dirty = true }
                }
                ComboBox {
                    objectName: "categoryBox"
                    Layout.fillWidth: true
                    model: Store.infoCategories.map(c => c.name)
                    currentIndex: Store.infoCategories.findIndex(c => c.code === row.code)
                    onActivated: {
                        rows.setProperty(row.index, "code", Store.infoCategories[currentIndex].code)
                        dialog.dirty = true
                    }
                }
                TextField {
                    objectName: "valueField"
                    Layout.preferredWidth: dialog.wValue
                    horizontalAlignment: TextInput.AlignRight
                    unit: row.category ? row.category.unit : ""
                    text: row.value
                    onTextEdited: { rows.setProperty(row.index, "value", text); dialog.dirty = true }
                    onAccepted: dialog.save()
                }
                IconToolButton {
                    objectName: "removeButton"
                    Layout.preferredWidth: dialog.wRemove
                    Layout.preferredHeight: dialog.wRemove
                    iconName: "trash-2"
                    toolTip: "Entfernen"
                    // Removing destroys this row, so it comes last
                    onClicked: {
                        dialog.dirty = true
                        rows.remove(row.index)
                    }
                }
            }
        }

        Label {
            visible: rows.count === 0
            text: "Keine Einträge in dieser Woche."
            color: Styles.TokenInterface.semantics.text_muted
        }

        Label {
            Layout.fillWidth: true
            visible: dialog.error !== ""
            wrapMode: Text.Wrap
            text: dialog.error
            color: Styles.TokenInterface.semantics.danger_default
        }
    }

    footer: DialogButtons {
        // On the line of the dialog's buttons, at the left; never part of
        // the scrolled rows
        leading: IconButton {
            objectName: "addButton"
            iconName: "plus"
            text: "Hinzufügen"
            onClicked: dialog.addRow()
        }
        Button {
            objectName: "cancelButton"
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.cancel()
        }
        IconButton {
            objectName: "saveButton"
            iconName: "save"
            text: "Speichern"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }
}
