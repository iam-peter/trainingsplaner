import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Competition results per athlete, and their development over the years.
Page {
    id: page

    property string athleteId
    property var list: []
    property var current: null   // the competition being edited, null = new
    property bool dirty: false
    property string error
    property var trend: ({})

    function selectDefaultAthlete() {
        if (athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
    }

    function reload() {
        list = athleteId !== "" ? Store.competitions(athleteId) : []
        reloadTrend()
    }

    function reloadTrend() {
        const types = []
        for (let i = 0; i < typeChecks.count; ++i)
            if (typeChecks.itemAt(i).checked)
                types.push(i)
        trend = athleteId !== "" ? Store.competitionTrend(athleteId, fromYear.value, toYear.value,
                                                          periodBox.currentIndex, types) : ({})
    }

    function showChart() {
        tabs.currentIndex = 1
    }

    function edit(c) {
        current = c
        error = ""
        dateField.text = c ? c.dateText : Store.formatDate(Store.today())
        timeField.text = c ? c.time : ""
        typeBox.currentIndex = c ? c.type : 0
        nameField.text = c ? c.name : ""
        placeField.text = c ? c.place : ""
        weightField.text = c && c.bodyWeight > 0 ? c.bodyWeight.toLocaleString(Qt.locale("de_DE"), "f", 1) : ""
        for (let i = 0; i < 3; ++i) {
            snatchRepeater.itemAt(i).setValue(c ? c.snatch[i] : 0)
            cjRepeater.itemAt(i).setValue(c ? c.cleanJerk[i] : 0)
        }
        noteField.text = c ? c.note : ""
        dirty = false
        updateTotal()
    }

    function attempts(rep) {
        const a = []
        for (let i = 0; i < 3; ++i)
            a.push(rep.itemAt(i).value)
        return a
    }

    function best(a) { return Math.max(0, ...a) }

    function updateTotal() {
        const s = best(attempts(snatchRepeater)), c = best(attempts(cjRepeater))
        totalLabel.text = s > 0 && c > 0 ? String(s + c) : "–"
    }

    Shortcut {
        sequences: [StandardKey.Save]
        enabled: page.visible && page.dirty && tabs.currentIndex === 0 && DialogStack.open === 0
        onActivated: page.save()
    }

    function save() {
        error = Store.saveCompetition({
            athleteId: athleteId,
            date: dateField.text,
            time: timeField.text,
            type: typeBox.currentIndex,
            name: nameField.text,
            place: placeField.text,
            bodyWeight: weightField.text,
            snatch: attempts(snatchRepeater),
            cleanJerk: attempts(cjRepeater),
            note: noteField.text
        }, current ? current.date : "", current ? current.time : "")
        if (error === "") {
            const date = Store.parseDate(dateField.text)
            reload()
            edit(list.find(c => c.date === date) || null)
        }
    }

    onAthleteIdChanged: { reload(); edit(null) }
    Connections {
        target: Store
        function onAthletesChanged() { page.selectDefaultAthlete() }
    }
    Component.onCompleted: {
        selectDefaultAthlete()
        reload()
        edit(null)
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            ComboBox {
                Layout.preferredWidth: 220
                model: Store.selectableAthletes
                textRole: "displayName"
                valueRole: "id"
                currentIndex: indexOfValue(page.athleteId)
                displayText: currentIndex < 0 ? "Sportler wählen" : currentText
                onActivated: page.athleteId = currentValue
            }
            AppTabBar {
                id: tabs
                Layout.preferredWidth: 260
                AppTabButton { text: "Ergebnisse" }
                AppTabButton { text: "Grafik" }
            }
            Item { Layout.fillWidth: true }
        }
    }

    StackLayout {
        anchors.fill: parent
        // Lined up with the toolbar above (8 px from the window edge)
        anchors.margins: 8
        currentIndex: tabs.currentIndex
        visible: page.athleteId !== ""

        // Results: list and form
        RowLayout {
            spacing: 12

            Panel {
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                // Rows stay inside the border
                padding: 1
                filled: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        // With the rows' inset, the selection keeps the same gap to the
                        // border on every side
                        topMargin: Theme.listMargin
                        bottomMargin: Theme.listMargin
                        model: page.list
                        ScrollBar.vertical: ScrollBar {}
                        delegate: ListRow {
                            required property var modelData
                            highlighted: page.current && page.current.date === modelData.date
                                         && page.current.time === modelData.time
                            deleteToolTip: "Wettkampf löschen"
                            onClicked: page.edit(modelData)
                            onDeleteRequested: {
                                deleteConfirm.competition = modelData
                                deleteConfirm.open()
                            }
                            contentItem: RowLayout {
                                Label { text: modelData.dateText; Layout.preferredWidth: 80 }
                                Label { text: modelData.typeName; Layout.preferredWidth: 28; color: palette.placeholderText }
                                Label { text: modelData.name || modelData.place; Layout.fillWidth: true; elide: Text.ElideRight }
                                Label { text: modelData.total > 0 ? modelData.total : "–"; font.bold: true }
                            }
                        }
                        Label {
                            anchors.centerIn: parent
                            visible: page.list.length === 0
                            text: "Noch keine Wettkämpfe."
                            color: palette.placeholderText
                        }
                    }
                    IconButton {
                        Layout.fillWidth: true
                        Layout.margins: 8
                        iconName: "plus"
                        text: "Neuer Wettkampf"
                        onClicked: page.edit(null)
                    }
                }
            }

            Panel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                GridLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 8

                    Label {
                        Layout.columnSpan: 2
                        text: page.current ? "Wettkampf bearbeiten" : "Neuer Wettkampf"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    Label { text: "Datum / Zeit:" }
                    RowLayout {
                        DateField { id: dateField; onTextEdited: page.dirty = true }
                        TextField { id: timeField; implicitWidth: 70; placeholderText: "HH:MM"; onTextEdited: page.dirty = true }
                    }
                    Label { text: "Art:" }
                    ComboBox {
                        id: typeBox
                        implicitWidth: 240
                        model: Store.competitionTypes
                        onActivated: page.dirty = true
                    }
                    Label { text: "Wettkampf:" }
                    TextField { id: nameField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }
                    Label { text: "Ort:" }
                    TextField { id: placeField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }
                    Label { text: "Körpergewicht:" }
                    RowLayout {
                        TextField { id: weightField; implicitWidth: 80; horizontalAlignment: TextInput.AlignRight; onTextEdited: page.dirty = true }
                        Label { text: "kg" }
                    }
                    Label { text: "Reißen:" }
                    RowLayout {
                        Repeater {
                            id: snatchRepeater
                            model: 3
                            AttemptField {
                                required property int index
                                objectName: "snatch" + index
                                onEdited: { page.dirty = true; page.updateTotal() }
                            }
                        }
                    }
                    Label { text: "Stoßen:" }
                    RowLayout {
                        Repeater {
                            id: cjRepeater
                            model: 3
                            AttemptField {
                                required property int index
                                objectName: "cleanJerk" + index
                                onEdited: { page.dirty = true; page.updateTotal() }
                            }
                        }
                        Label {
                            text: "Fehlversuch: Leertaste oder Rechtsklick im Feld (rot, durchgestrichen)"
                            font.pixelSize: 11
                            color: palette.placeholderText
                        }
                    }
                    Label { text: "Zweikampf:" }
                    Label { id: totalLabel; font.bold: true; font.pixelSize: 16 }
                    Label { text: "Bemerkung:" }
                    TextField { id: noteField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }

                    Item {}
                    RowLayout {
                        IconButton {
                            iconName: page.current ? "save" : "plus"
                            text: page.current ? "Speichern" : "Hinzufügen"
                            highlighted: true
                            enabled: page.dirty || !page.current
                            onClicked: page.save()
                        }
                    }
                    Label {
                        Layout.columnSpan: 2
                        visible: page.error !== ""
                        text: page.error
                        color: Theme.error
                    }
                }
            }
        }

        // Development over the years
        ColumnLayout {
            spacing: 8
            RowLayout {
                spacing: 8
                Label { text: "von" }
                SpinBox { id: fromYear; from: 1990; to: 2100; value: new Date().getFullYear() - 4; editable: true; textFromValue: v => String(v); onValueModified: page.reloadTrend() }
                Label { text: "bis" }
                SpinBox { id: toYear; from: 1990; to: 2100; value: new Date().getFullYear(); editable: true; textFromValue: v => String(v); onValueModified: page.reloadTrend() }
                Label { text: "Bestes Resultat:" }
                ComboBox {
                    id: periodBox
                    model: ["jeder Wettkampf", "halbjährlich", "jährlich"]
                    onActivated: page.reloadTrend()
                }
            }
            RowLayout {
                spacing: 4
                Repeater {
                    id: typeChecks
                    model: ["NT", "DM", "IT", "BL", "EM", "WM", "OS"]
                    CheckBox {
                        required property string modelData
                        text: modelData
                        checked: true
                        onToggled: page.reloadTrend()
                    }
                }
                Item { Layout.preferredWidth: 12 }
                CheckBox { id: showValues; text: "Werte"; checked: true }
                CheckBox { id: showTrend; text: "Trend" }
                CheckBox { id: showNorm; text: "Norm Bundeskader"; enabled: (page.trend.norm || 0) > 0 }
                Item { Layout.fillWidth: true }
                IconButton {
                    iconName: "file-down"
                    text: "Bild…"
                    toolTip: "Grafik als PNG-Bild speichern"
                    onClicked: competitionChart.saveImage()
                }
                IconButton {
                    iconName: "printer"
                    text: "Drucken…"
                    onClicked: competitionChart.printChart()
                }
            }
            TrendChart {
                id: competitionChart
                documentTitle: "Wettkampfentwicklung"
                Layout.fillWidth: true
                Layout.fillHeight: true
                labels: page.trend.labels || []
                showValues: showValues.checked
                leftTitle: "kg"
                lines: [
                    { name: "Zweikampf", color: Theme.accent, values: page.trend.total || [], trend: showTrend.checked },
                    { name: "Reißen", color: Theme.ink, values: page.trend.snatch || [], trend: showTrend.checked },
                    { name: "Stoßen", color: Theme.blue, values: page.trend.cleanJerk || [], trend: showTrend.checked }
                ]
                references: showNorm.checked && page.trend.norm > 0
                            ? [{ name: "Norm " + page.trend.norm + " kg", color: Theme.green, value: page.trend.norm }] : []
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: page.athleteId === ""
        text: "Bitte einen Sportler wählen."
        color: palette.placeholderText
    }

    AppDialog {
        id: deleteConfirm
        property var competition: null
        title: "Wettkampf löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: deleteConfirm.competition
                  ? deleteConfirm.competition.dateText + "  " + (deleteConfirm.competition.name || deleteConfirm.competition.place)
                    + " wird gelöscht.\nDas kann nicht rückgängig gemacht werden."
                  : ""
        }
        onAccepted: {
            const c = deleteConfirm.competition
            const wasSelected = page.current && page.current.date === c.date && page.current.time === c.time
            Store.removeCompetition(page.athleteId, c.date, c.time)
            page.reload()
            if (wasSelected)
                page.edit(null)
        }
    }
}
