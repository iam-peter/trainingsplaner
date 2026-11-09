import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Extra info per day (Zusatzinfo): body weight, body fat, supplements ...
// for the days of one week.
AppDialog {
    id: dialog

    property string athleteId
    property string monday
    property var entries: []
    property string error
    // The entry being edited, null for a new one
    property var editing: null

    function edit(a, m) {
        athleteId = a
        monday = m
        editing = null
        reload()
        resetForm()
        open()
    }

    function reload() {
        entries = Store.dayInfo(athleteId, monday)
        summary.text = Store.weekInfoSummary(athleteId, monday)
    }

    function resetForm() {
        editing = null
        error = ""
        const today = Store.today()
        const dayIndex = Store.mondayOf(today) === monday ? (new Date(today).getDay() + 6) % 7 : 0
        dayBox.currentIndex = dayIndex
        valueField.text = ""
        timeField.text = ""
    }

    function startEdit(e) {
        editing = e
        error = ""
        for (let i = 0; i < 7; ++i) {
            if (dayDate(i) === e.date)
                dayBox.currentIndex = i
        }
        categoryBox.currentIndex = Math.max(0, Store.infoCategories.findIndex(c => c.code === e.code))
        timeField.text = e.time
        valueField.text = e.valueText
        valueField.forceActiveFocus()
    }

    function dayDate(i) {
        const d = new Date(monday + "T12:00:00")
        d.setDate(d.getDate() + i)
        return d.toISOString().slice(0, 10)
    }

    function save() {
        const cat = Store.infoCategories[categoryBox.currentIndex]
        error = Store.saveDayInfo(athleteId, dayDate(dayBox.currentIndex), timeField.time, cat ? cat.code : "",
                                  valueField.text,
                                  editing ? editing.date : "", editing ? editing.time : "", editing ? editing.code : "")
        if (error === "") {
            reload()
            resetForm()
            valueField.forceActiveFocus()
        }
    }

    title: "Zusatzinfo  –  Woche " + Store.weekLabel(monday)
    // As wide as its row of fields needs, at least 640 px
    width: Math.min(parent ? parent.width - 40 : 100000, Math.max(640, implicitWidth))
    height: Math.min(parent ? parent.height - 60 : 600, 620)
    // Fixed height; scrolls its content itself
    scrollsContent: false
    standardButtons: Dialog.Close

    contentItem: ColumnLayout {
        spacing: 8

        GridLayout {
            columns: 5
            columnSpacing: 8
            rowSpacing: 4
            Label { text: "Tag"; font.pixelSize: 11 }
            Label { text: "Zeit"; font.pixelSize: 11 }
            Label { text: "Kategorie"; font.pixelSize: 11 }
            Label { text: "Wert"; font.pixelSize: 11 }
            Item {}
            ComboBox {
                id: dayBox
                implicitWidth: 150
                model: [1, 2, 3, 4, 5, 6, 7].map(d => Store.dayName(d) + ", " + Store.dayDate(dialog.monday, d))
            }
            TimeField { id: timeField; objectName: "timeField" }
            ComboBox {
                id: categoryBox
                implicitWidth: 170
                model: Store.infoCategories.map(c => c.name)
            }
            RowLayout {
                spacing: 4
                TextField {
                    id: valueField
                    objectName: "valueField"
                    implicitWidth: 80
                    horizontalAlignment: TextInput.AlignRight
                    onAccepted: dialog.save()
                }
                Label {
                    text: Store.infoCategories[categoryBox.currentIndex]
                          ? Store.infoCategories[categoryBox.currentIndex].unit : ""
                }
            }
            RowLayout {
                spacing: 8
                IconButton {
                    iconName: dialog.editing ? "save" : "plus"
                    text: dialog.editing ? "Speichern" : "Hinzufügen"
                    onClicked: dialog.save()
                }
                IconToolButton {
                    // Keeps its room while hidden, so the dialog does not
                    // widen when an entry is edited
                    opacity: dialog.editing !== null ? 1 : 0
                    enabled: dialog.editing !== null
                    iconName: "x"
                    toolTip: "Bearbeiten abbrechen"
                    onClicked: dialog.resetForm()
                }
            }
        }

        Label {
            visible: dialog.error !== ""
            text: dialog.error
            color: Theme.error
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

        ListView {
            boundsBehavior: Flickable.StopAtBounds
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: dialog.entries
            ScrollBar.vertical: AppScrollBar {}
            delegate: ItemDelegate {
                required property var modelData
                width: ListView.view.width - (ListView.view.ScrollBar.vertical?.room ?? 0)
                highlighted: dialog.editing && dialog.editing.date === modelData.date
                             && dialog.editing.code === modelData.code && dialog.editing.time === modelData.time
                onClicked: dialog.startEdit(modelData)
                contentItem: RowLayout {
                    spacing: 8
                    Label { text: modelData.dateText; Layout.preferredWidth: 150 }
                    Label { text: modelData.time; Layout.preferredWidth: 60; color: palette.placeholderText }
                    Label { text: modelData.name; Layout.fillWidth: true }
                    Label { text: modelData.valueText + " " + modelData.unit; font.bold: true }
                    IconToolButton {
                        iconName: "trash-2"
                        toolTip: "Löschen"
                        onClicked: {
                            Store.removeDayInfo(dialog.athleteId, modelData.code, modelData.date, modelData.time)
                            dialog.reload()
                            dialog.resetForm()
                        }
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                visible: dialog.entries.length === 0
                text: "Keine Einträge in dieser Woche."
                color: palette.placeholderText
            }
        }

        Label {
            id: summary
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.bold: true
        }
    }
}
