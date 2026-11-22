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
    // The athlete whose competition the form holds: it is saved to them
    // when another athlete is chosen meanwhile
    property string formAthlete
    property string error
    property var trend: ({})

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true

    function selectDefaultAthlete() {
        if (choosesAthlete && athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
    }

    property bool stale: false
    onVisibleChanged: if (visible && stale) reload()

    function reload() {
        stale = false
        list = athleteId !== "" ? Store.competitions(athleteId) : []
        reloadTrend()
    }

    // The list with the competitions to come under their own heading,
    // the next one first, above the results, the latest first; headings
    // only when there are some to come
    readonly property var groupedList: {
        const today = Store.today()
        const coming = c => c.date > today || (c.date === today && c.total <= 0)
        const ahead = list.filter(coming)
        if (ahead.length === 0)
            return list
        // The list comes latest first: the ones to come reversed
        return ahead.slice().reverse().map(c => Object.assign({}, c, { group: "Anstehend" }))
               .concat(list.filter(c => !coming(c)).map(c => Object.assign({}, c, { group: "Ergebnisse" })))
    }

    function reloadTrend() {
        const types = []
        for (let i = 0; i < typeChecks.count; ++i)
            if (typeChecks.itemAt(i).checked)
                types.push(i)
        trend = athleteId !== "" ? Store.competitionTrend(athleteId, fromYear.value, toYear.value,
                                                          periodBox.currentIndex, types,
                                                          showCurve.checked && periodBox.currentIndex === 2) : ({})
    }

    function showChart() {
        tabs.currentIndex = 1
    }

    function edit(c) {
        current = c
        formAthlete = athleteId
        error = ""
        dateField.text = c ? c.dateText : Store.formatDate(Store.today())
        timeField.text = c ? c.time : ""
        typeBox.currentIndex = c ? c.type : 0
        nameField.text = c ? c.name : ""
        placeField.text = c ? c.place : ""
        weightField.text = c && c.bodyWeight > 0 ? c.bodyWeight.toLocaleString(Qt.locale("de_DE"), "f", 1) : ""
        // (the attempt fields are not made yet while the page is built)
        for (let i = 0; i < Math.min(3, snatchRepeater.count, cjRepeater.count); ++i) {
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
            a.push(rep.itemAt(i) ? rep.itemAt(i).value : 0)
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
        const owner = formAthlete !== "" ? formAthlete : athleteId
        error = Store.saveCompetition({
            athleteId: owner,
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
            dirty = false
            if (owner !== athleteId)
                return
            // Read anew: a hidden page only marks its list as stale
            reload()
            const date = Store.parseDate(dateField.text)
            edit(list.find(c => c.date === date) || null)
        }
    }

    // Before another competition or athlete is shown: what was edited is
    // saved, as the session panel does. False when it cannot be; the form
    // then stays and says why.
    function leave() {
        if (dirty)
            save()
        return !dirty
    }

    // Chosen on another page while this form had edits: they go to the
    // athlete they were made for
    onAthleteIdChanged: {
        if (dirty && formAthlete !== "" && formAthlete !== athleteId)
            save()
        reload()
        edit(null)
    }
    Connections {
        target: Store
        function onAthletesChanged() { page.selectDefaultAthlete() }
        // Competitions entered elsewhere (the month view): the list and the
        // chart follow; the form keeps what is being edited
        // (while another page is shown, once it shows again)
        function onDataVersionChanged() {
            if (page.visible)
                page.reload()
            else
                page.stale = true
        }
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
                id: athleteBox
                Layout.preferredWidth: 220
                model: Store.selectableAthletes
                value: page.athleteId
                displayText: currentIndex < 0 ? "Sportler wählen" : currentText
                onChosen: (v) => {
                    if (page.leave())
                        page.athleteId = v
                    else
                        athleteBox.sync()
                }
            }
            AppTabBar {
                id: tabs
                Layout.preferredWidth: 260
                AppTabButton { text: "Ergebnisse" }
                AppTabButton { text: "Grafik" }
            }
            // A youth athlete: the age class, the weight class and how far
            // the DM Nachwuchs norm is (DGJ rules, norms in the settings)
            Label {
                objectName: "youthStatus"
                Layout.fillWidth: true
                Layout.leftMargin: 8
                elide: Text.ElideRight
                readonly property var status: page.athleteId !== ""
                                              ? (Store.dataVersion, Store.dmNorms, Store.youthStatus(page.athleteId, Store.today())) : ({})
                visible: status.youth === true
                text: status.youth ? "AK " + status.ageClass + (status.weightClass ? " · " + status.weightClass + " kg" : "")
                                     + (status.dm && status.dm.text ? " · " + status.dm.text : "") : ""
                color: status.dm && status.dm.reached ? Styles.TokenInterface.semantics.text_default
                                                      : Styles.TokenInterface.semantics.text_muted
            }
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
                model: page.groupedList
                sectionField: page.groupedList.length > 0 && page.groupedList[0].group ? "group" : ""
                emptyText: "Noch keine Wettkämpfe."
                addText: "Neuer Wettkampf"
                onAddClicked: if (page.leave()) page.edit(null)
                delegate: ListRow {
                    required property var modelData
                    highlighted: page.current && page.current.date === modelData.date
                                 && page.current.time === modelData.time
                    deleteToolTip: "Wettkampf löschen"
                    onClicked: if (page.leave()) page.edit(modelData)
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

            FormPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: page.current ? "Wettkampf bearbeiten" : "Neuer Wettkampf"

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
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.fieldWidth
                    onTextEdited: page.dirty = true
                }
                Label { text: "Ort:" }
                TextField {
                    id: placeField
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.fieldWidth
                    onTextEdited: page.dirty = true
                }
                Label { text: "Körpergewicht:" }
                TextField {
                    id: weightField
                    implicitWidth: 100
                    unit: "kg"
                    onTextEdited: page.dirty = true
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
                }
                Item {}
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "Fehlversuch: Leertaste oder Rechtsklick im Feld (rot, durchgestrichen)"
                    font.pixelSize: 11
                    color: Styles.TokenInterface.semantics.text_muted
                }
                Label { text: "Zweikampf:" }
                Label { id: totalLabel; font.bold: true; font.pixelSize: 16 }
                Label { text: "Bemerkung:" }
                TextField {
                    id: noteField
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.fieldWidth
                    onTextEdited: page.dirty = true
                }

                buttons: [
                    IconButton {
                        iconName: page.current ? "save" : "plus"
                        text: page.current ? "Speichern" : "Hinzufügen"
                        highlighted: true
                        enabled: page.dirty || !page.current
                        onClicked: page.save()
                    },
                    Label {
                        visible: page.error !== ""
                        text: page.error
                        color: Styles.TokenInterface.semantics.danger_default
                    },
                    Item { Layout.fillWidth: true },
                    Label {
                        objectName: "saveNote"
                        visible: page.dirty
                        text: "Wird beim Wechsel gespeichert"
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                    }
                ]
            }
        }

        // Development over the years
        ColumnLayout {
            spacing: 8
            RowLayout {
                spacing: 8
                Label { text: "von" }
                // The other year follows, so "von" never lies after "bis"
                SpinBox {
                    id: fromYear
                    objectName: "fromYear"
                    from: 1990; to: 2100; value: new Date().getFullYear() - 4; editable: true
                    textFromValue: v => String(v)
                    onValueModified: {
                        if (toYear.value < value)
                            toYear.value = value
                        page.reloadTrend()
                    }
                }
                Label { text: "bis" }
                SpinBox {
                    id: toYear
                    objectName: "toYear"
                    from: 1990; to: 2100; value: new Date().getFullYear(); editable: true
                    textFromValue: v => String(v)
                    onValueModified: {
                        if (fromYear.value > value)
                            fromYear.value = value
                        page.reloadTrend()
                    }
                }
                Label { text: "Bestes Resultat:" }
                ComboBox {
                    id: periodBox
                    objectName: "periodBox"
                    model: ["jeder Wettkampf", "halbjährlich", "jährlich"]
                    onActivated: page.reloadTrend()
                }
                // Sandau's Gompertz curve over the yearly bests, two years
                // ahead with its standard error as a band
                CheckBox {
                    id: showCurve
                    objectName: "showCurve"
                    text: "Entwicklungskurve"
                    enabled: periodBox.currentIndex === 2
                    onToggled: page.reloadTrend()
                    ToolTip.visible: hovered
                    ToolTip.text: periodBox.currentIndex === 2
                                  ? "Gompertz-Kurve nach Sandau (2018) über die Jahresbesten, zwei Jahre voraus"
                                  : "Nur mit „jährlich“"
                }
                ComboBox {
                    id: whatBox
                    objectName: "whatBox"
                    model: ["Leistung", "Körpergewicht"]
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
                // The reference total: the BVDG's KET 2026 (NK1, PK) or the
                // old program's table of 2005, in the order the Store gives
                CheckBox {
                    id: showNorm
                    objectName: "showNorm"
                    text: "Norm"
                    enabled: normBox.value > 0
                }
                ComboBox {
                    id: normBox
                    objectName: "normBox"
                    readonly property var norm: (page.trend.norms || [])[currentIndex]
                    readonly property int value: norm ? norm.value : 0
                    model: ["KET NK1", "KET PK", "WinWoTA 2005"]
                    displayText: currentText + (value > 0 ? ": " + value + " kg" : ": –")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    ToolTip.text: norm ? norm.tip : ""
                }
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
                readonly property bool body: whatBox.currentIndex === 1
                readonly property bool curve: showCurve.checked && showCurve.enabled && page.trend.curve !== undefined
                lines: {
                    const s = Styles.TokenInterface.semantics
                    if (body) {
                        const l = [{ name: "Körpergewicht", color: s.primary_default, values: page.trend.bodyWeight || [], trend: showTrend.checked }]
                        if (curve && (page.trend.bodyCurve || []).length > 0)
                            l.push({ name: "Entwicklungskurve", color: s.primary_default, values: page.trend.bodyCurve, trend: false, dashed: true,
                                     valuesFrom: page.trend.labels.length - 2 })
                        return l
                    }
                    const l = [
                        { name: "Zweikampf", color: s.primary_default, values: page.trend.total || [], trend: showTrend.checked },
                        { name: "Reißen", color: s.chart_series[1], values: page.trend.snatch || [], trend: showTrend.checked },
                        { name: "Stoßen", color: s.chart_series[2], values: page.trend.cleanJerk || [], trend: showTrend.checked }
                    ]
                    if (curve && (page.trend.curve || []).length > 0)
                        l.push({ name: "Entwicklungskurve Zweikampf", color: s.primary_default, values: page.trend.curve, trend: false, dashed: true,
                                 valuesFrom: page.trend.labels.length - 2 })
                    return l
                }
                bands: {
                    if (!curve)
                        return []
                    const lower = body ? page.trend.bodyLower : page.trend.curveLower
                    const upper = body ? page.trend.bodyUpper : page.trend.curveUpper
                    return (lower || []).length > 0
                           ? [{ name: "± Standardfehler", color: Styles.TokenInterface.semantics.primary_default, lower: lower, upper: upper }] : []
                }
                references: body
                            ? (page.trend.classLimits || []).map(v => ({ name: "Klasse " + v + " kg", color: Styles.TokenInterface.semantics.chart_series[3], value: v }))
                            : showNorm.checked && normBox.value > 0
                              ? [{ name: "Norm " + normBox.currentText + " " + normBox.value + " kg", color: Styles.TokenInterface.semantics.chart_series[3],
                                   value: normBox.value }] : []
            }
            Label {
                objectName: "curveText"
                visible: competitionChart.curve && text !== ""
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 11
                color: Styles.TokenInterface.semantics.text_muted
                text: (whatBox.currentIndex === 1 ? page.trend.bodyText : page.trend.curveText) || ""
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
