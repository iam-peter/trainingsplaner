import QtQuick
import TrainingsplanerStyle as Styles
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

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true

    function selectDefaultAthlete() {
        if (choosesAthlete && athleteId === "" && Store.selectableAthletes.length > 0)
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
            time: timeField.time,
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
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            ValueComboBox {
                Layout.preferredWidth: 220
                model: Store.selectableAthletes
                value: page.athleteId
                displayText: currentIndex < 0 ? "Sportler wählen" : currentText
                onChosen: (v) => page.athleteId = v
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
            spacing: 8

            ListPanel {
                objectName: "competitionList"
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                model: page.list
                emptyText: "Noch keine Wettkämpfe."
                addText: "Neuer Wettkampf"
                onAddClicked: page.edit(null)
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
                        spacing: 8
                        Label { text: modelData.dateText; Layout.preferredWidth: 80 }
                        Label { text: modelData.typeName; Layout.preferredWidth: 28; color: Styles.TokenInterface.semantics.text_muted }
                        Label { text: modelData.name || modelData.place; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: modelData.total > 0 ? modelData.total : "–"; font.bold: true }
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
                        id: dateRow
                        spacing: 8
                        DateField { id: dateField; onTextEdited: page.dirty = true }
                        TimeField { id: timeField; objectName: "timeField"; onTextEdited: page.dirty = true }
                    }
                    Label { text: "Art:" }
                    ComboBox {
                        id: typeBox
                        // Ends with Datum / Zeit above it
                        implicitWidth: dateRow.implicitWidth
                        model: Store.competitionTypes
                        onActivated: page.dirty = true
                    }
                    Label { text: "Wettkampf:" }
                    TextField { id: nameField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }
                    Label { text: "Ort:" }
                    TextField { id: placeField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }
                    Label { text: "Körpergewicht:" }
                    RowLayout {
                        spacing: 8
                        TextField { id: weightField; implicitWidth: 80; horizontalAlignment: TextInput.AlignRight; onTextEdited: page.dirty = true }
                        Label { text: "kg" }
                    }
                    Label { text: "Reißen:" }
                    RowLayout {
                        spacing: 8
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
                        spacing: 8
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
                            color: Styles.TokenInterface.semantics.text_muted
                        }
                    }
                    Label { text: "Zweikampf:" }
                    Label { id: totalLabel; font.bold: true; font.pixelSize: 16 }
                    Label { text: "Bemerkung:" }
                    TextField { id: noteField; Layout.preferredWidth: 320; onTextEdited: page.dirty = true }

                    Item {}
                    RowLayout {
                        spacing: 8
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
                        color: Styles.TokenInterface.semantics.danger_default
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
                    text: "Bild"
                    toolTip: "Grafik als PNG-Bild speichern"
                    onClicked: competitionChart.saveImage()
                }
                IconButton {
                    iconName: "printer"
                    text: "Drucken"
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
                    { name: "Zweikampf", color: Styles.TokenInterface.semantics.primary_default, values: page.trend.total || [], trend: showTrend.checked },
                    { name: "Reißen", color: Styles.TokenInterface.semantics.chart_series[1], values: page.trend.snatch || [], trend: showTrend.checked },
                    { name: "Stoßen", color: Styles.TokenInterface.semantics.chart_series[2], values: page.trend.cleanJerk || [], trend: showTrend.checked }
                ]
                references: showNorm.checked && page.trend.norm > 0
                            ? [{ name: "Norm " + page.trend.norm + " kg", color: Styles.TokenInterface.semantics.chart_series[3], value: page.trend.norm }] : []
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: page.athleteId === ""
        text: "Bitte einen Sportler wählen."
        color: Styles.TokenInterface.semantics.text_muted
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
