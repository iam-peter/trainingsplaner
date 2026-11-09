import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Analyses: section analysis of an athlete, group analysis of a MAZ, data
// check, and charts.
Page {
    id: page

    property string athleteId

    function selectDefaultAthlete() {
        if (athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
    }
    Component.onCompleted: selectDefaultAthlete()

    // For start options: "individual", "group", "check", "chart"
    function show(name) {
        tabs.currentIndex = ["individual", "group", "check", "chart"].indexOf(name) >= 0
                            ? ["individual", "group", "check", "chart"].indexOf(name) : 0
        if (tabs.currentIndex === 0) individualReport.html = Analysis.individual(individualParams())
        if (tabs.currentIndex === 3) chartTab.reload()
    }

    readonly property var athleteMaz: athleteId !== "" ? (Plan.changed, Plan.mazForAthlete(athleteId)) : []
    readonly property string defaultFrom: Store.weekLabel(Store.addWeeks(Store.mondayOf(Store.today()), -11))

    function individualParams() {
        return {
            athleteId: athleteId,
            mazId: iMaz.currentValue || "",
            from: iFrom.text, weeks: iWeeks.value,
            basis: iPlan.checked ? "P" : iItp.checked ? "T" : "I",
            reference: iZiel.checked ? "ziel" : iWk.checked ? "wk" : "kg",
            groups: iGroups.checked,
            competitionWeeks: iCompWeeks.checked,
            summary: iSummary.checked,
            compareMazId: iCompare.currentValue || "",
            compareBasis: ["I", "P", "T", "R"][iCompareBasis.currentIndex],
            allMaz: iAllMaz.checked,
            loadExercise: iLoad.checked ? (parseInt(iLoadEx.text) || 0) : 0
        }
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            AppTabBar {
                id: tabs
                Layout.preferredWidth: 560
                AppTabButton { text: "Individualanalyse" }
                AppTabButton { text: "Gruppenanalyse" }
                AppTabButton { text: "Datenprüfung" }
                AppTabButton { text: "Grafik" }
            }
            Item { Layout.fillWidth: true }
        }
    }

    StackLayout {
        anchors.fill: parent
        anchors.margins: 12
        currentIndex: tabs.currentIndex

        // Section analysis of one athlete
        RowLayout {
            spacing: 12
            ScrollView {
                // No overshoot at the ends
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                Layout.preferredWidth: 330
                Layout.fillHeight: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 8
                    Label { text: "Sportler"; font.bold: true }
                    ComboBox {
                        Layout.fillWidth: true
                        model: Store.selectableAthletes
                        textRole: "displayName"
                        valueRole: "id"
                        currentIndex: indexOfValue(page.athleteId)
                        onActivated: page.athleteId = currentValue
                    }
                    Label { text: "Zeitraum"; font.bold: true }
                    ComboBox {
                        id: iMaz
                        Layout.fillWidth: true
                        model: [{ id: "", displayName: "Wochen" }].concat(page.athleteMaz)
                        textRole: "displayName"
                        valueRole: "id"
                    }
                    RowLayout {
                        visible: iMaz.currentIndex <= 0
                        Label { text: "ab" }
                        TextField { id: iFrom; implicitWidth: 80; text: page.defaultFrom }
                        SpinBox { id: iWeeks; from: 1; to: 104; value: 12; editable: true }
                        Label { text: "Wochen" }
                    }
                    CheckBox { id: iCompWeeks; text: "WK-Woche einschließen" }
                    Label { text: "Bezug"; font.bold: true }
                    RowLayout {
                        RadioButton { id: iIst; text: "Ist"; checked: true }
                        RadioButton { id: iPlan; text: "Plan" }
                        RadioButton { id: iItp; text: "ITP" }
                    }
                    RowLayout {
                        RadioButton { id: iKg; text: "kg"; checked: true }
                        RadioButton { id: iZiel; text: "% MAZ-Ziel"; enabled: iMaz.currentIndex > 0 }
                        RadioButton { id: iWk; text: "% MAZ-WK"; enabled: iMaz.currentIndex > 0 }
                    }
                    CheckBox { id: iGroups; text: "Komplexe K1–K7 statt Übungen" }
                    CheckBox { id: iSummary; text: "Zusammenfassung (ohne Wochenwerte)" }
                    Label { text: "Vergleich"; font.bold: true }
                    ComboBox {
                        id: iCompare
                        Layout.fillWidth: true
                        model: [{ id: "", displayName: "kein Vergleich" }].concat(Plan.mazList)
                        textRole: "displayName"
                        valueRole: "id"
                    }
                    ComboBox {
                        id: iCompareBasis
                        Layout.fillWidth: true
                        enabled: iCompare.currentIndex > 0
                        model: ["Ist", "Plan", "ITP", "Rahmenorientierung (RO)"]
                    }
                    CheckBox { id: iAllMaz; text: "Gesamtübersicht (alle MAZ)" }
                    RowLayout {
                        CheckBox { id: iLoad; text: "Laststufenanalyse TÜ" }
                        TextField { id: iLoadEx; implicitWidth: 44; text: "1"; enabled: iLoad.checked; validator: IntValidator { bottom: 1; top: 45 } }
                    }
                    IconButton {
                        Layout.topMargin: 8
                        iconName: "list"
                        text: "Tabelle"
                        highlighted: true
                        onClicked: individualReport.html = Analysis.individual(page.individualParams())
                    }
                }
            }
            ReportView {
                id: individualReport
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Abschnittsanalyse"
            }
        }

        // Group analysis of a MAZ
        RowLayout {
            spacing: 12
            ColumnLayout {
                Layout.preferredWidth: 330
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Label { text: "MAZ"; font.bold: true }
                ComboBox {
                    id: gMaz
                    Layout.fillWidth: true
                    model: Plan.mazList
                    textRole: "displayName"
                    valueRole: "id"
                }
                Label { text: "Auswertung"; font.bold: true }
                RadioButton { id: gOverview; text: "Gesamtübersicht"; checked: true }
                RadioButton { id: gVolume; text: "Umfangskennziffern" }
                RadioButton { id: gIntensity; text: "Intensitätskennziffern" }
                RowLayout {
                    enabled: gIntensity.checked
                    Label { text: "TÜ" }
                    TextField { id: gExercise; implicitWidth: 44; text: "1"; validator: IntValidator { bottom: 1; top: 45 } }
                    Label { text: Store.exerciseName(parseInt(gExercise.text) || 0); color: palette.placeholderText }
                }
                RowLayout {
                    enabled: gIntensity.checked
                    RadioButton { id: gKg; text: "kg"; checked: true }
                    RadioButton { id: gZiel; text: "% MAZ-Ziel" }
                    RadioButton { id: gWk; text: "% MAZ-WK" }
                }
                CheckBox { id: gCompWeeks; text: "WK-Woche einschließen" }
                IconButton {
                    Layout.topMargin: 8
                    iconName: "list"
                    text: "Tabelle"
                    highlighted: true
                    enabled: gMaz.currentIndex >= 0
                    onClicked: groupReport.html = Analysis.group({
                        mazId: gMaz.currentValue, mode: gVolume.checked ? 1 : gIntensity.checked ? 2 : 0,
                        exercise: parseInt(gExercise.text) || 1,
                        reference: gZiel.checked ? "ziel" : gWk.checked ? "wk" : "kg",
                        competitionWeeks: gCompWeeks.checked
                    })
                }
            }
            ReportView {
                id: groupReport
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Gruppenanalyse"
            }
        }

        // Which athletes have data
        RowLayout {
            spacing: 12
            ColumnLayout {
                Layout.preferredWidth: 330
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Label { text: "Zeitraum"; font.bold: true }
                RowLayout {
                    Label { text: "ab" }
                    TextField { id: cFrom; implicitWidth: 80; text: page.defaultFrom }
                    SpinBox { id: cWeeks; from: 1; to: 104; value: 12; editable: true }
                    Label { text: "Wochen" }
                }
                RadioButton { id: cTraining; text: "Trainingsdaten"; checked: true }
                RadioButton { text: "Wettkämpfe" }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: palette.placeholderText
                    text: "Alle Sportler der Auswahl aus den Einstellungen (Kader, Männer/Frauen)."
                }
                IconButton {
                    Layout.topMargin: 8
                    iconName: "list"
                    text: "Tabelle"
                    highlighted: true
                    onClicked: checkReport.html = Analysis.dataCheck({
                        from: cFrom.text, weeks: cWeeks.value, mode: cTraining.checked ? 0 : 1,
                        athletes: Store.selectableAthletes
                    })
                }
            }
            ReportView {
                id: checkReport
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Datenprüfung"
            }
        }

        // Charts
        ColumnLayout {
            id: chartTab
            spacing: 8
            property var first: ({})
            property var second: ({})
            function reload() {
                const ex = parseInt(chEx.text) || 1
                const common = {
                    exercise: ex, volume: chVolume.currentIndex,
                    basis: chPlan.checked ? "P" : chItp.checked ? "T" : "I",
                    reference: chZiel.checked ? "ziel" : chWk.checked ? "wk" : "kg",
                    from: chFrom.text, weeks: chWeeks.value
                }
                first = Analysis.series(Object.assign({ athleteId: page.athleteId, mazId: chMaz.currentValue || "" }, common))
                second = chCompare.checked && chAthlete2.currentIndex >= 0
                         ? Analysis.series(Object.assign({ athleteId: chAthlete2.currentValue, mazId: chMaz2.currentValue || "" }, common))
                         : ({})
            }
            RowLayout {
                spacing: 8
                ComboBox {
                    implicitWidth: 180
                    model: Store.selectableAthletes
                    textRole: "displayName"
                    valueRole: "id"
                    currentIndex: indexOfValue(page.athleteId)
                    onActivated: { page.athleteId = currentValue; chartTab.reload() }
                }
                ComboBox {
                    id: chMaz
                    implicitWidth: 200
                    model: [{ id: "", displayName: "Wochen" }].concat(page.athleteMaz)
                    textRole: "displayName"
                    valueRole: "id"
                    onActivated: chartTab.reload()
                }
                TextField { id: chFrom; visible: chMaz.currentIndex <= 0; implicitWidth: 80; text: page.defaultFrom; onEditingFinished: chartTab.reload() }
                SpinBox { id: chWeeks; visible: chMaz.currentIndex <= 0; from: 2; to: 104; value: 12; editable: true; onValueModified: chartTab.reload() }
                Label { text: "TÜ" }
                TextField {
                    id: chEx
                    implicitWidth: 44
                    text: "1"
                    validator: IntValidator { bottom: 1; top: 45 }
                    onEditingFinished: chartTab.reload()
                }
                Label { text: Store.exerciseName(parseInt(chEx.text) || 0); color: palette.placeholderText }
                Item { Layout.fillWidth: true }
                IconButton {
                    iconName: "file-down"
                    text: "Bild…"
                    toolTip: "Grafik als PNG-Bild speichern"
                    onClicked: analysisChart.saveImage()
                }
                IconButton {
                    iconName: "printer"
                    text: "Drucken…"
                    onClicked: analysisChart.printChart()
                }
            }
            RowLayout {
                spacing: 8
                CheckBox { id: chMhg; text: "MHG"; checked: true }
                CheckBox { id: chBw; text: "BW"; checked: true }
                CheckBox { id: chTrend; text: "Trend"; checked: true }
                CheckBox { id: chValues; text: "Werte" }
                Label { text: "Umfang:" }
                ComboBox {
                    id: chVolume
                    implicitWidth: 150
                    model: ["–", "Wh pro TÜ", "Komplex 1", "Komplex 2", "Komplex 3", "Komplex 4", "Komplex 5",
                            "Komplex 6", "Komplex 7", "Komplex 1-5", "Komplex 1-7"]
                    currentIndex: 1
                    onActivated: chartTab.reload()
                }
                RadioButton { text: "Ist"; checked: true; onToggled: chartTab.reload() }
                RadioButton { id: chPlan; text: "Plan"; onToggled: chartTab.reload() }
                RadioButton { id: chItp; text: "ITP"; onToggled: chartTab.reload() }
                Item { Layout.preferredWidth: 8 }
                RadioButton { text: "kg"; checked: true; onToggled: chartTab.reload() }
                RadioButton { id: chZiel; text: "% Ziel"; enabled: chMaz.currentIndex > 0; onToggled: chartTab.reload() }
                RadioButton { id: chWk; text: "% WK"; enabled: chMaz.currentIndex > 0; onToggled: chartTab.reload() }
            }
            RowLayout {
                spacing: 8
                CheckBox { id: chCompare; text: "Vergleich mit"; onToggled: chartTab.reload() }
                ComboBox {
                    id: chAthlete2
                    enabled: chCompare.checked
                    implicitWidth: 180
                    model: Store.selectableAthletes
                    textRole: "displayName"
                    valueRole: "id"
                    onActivated: chartTab.reload()
                }
                ComboBox {
                    id: chMaz2
                    enabled: chCompare.checked
                    implicitWidth: 200
                    model: [{ id: "", displayName: "gleiche Wochen" }].concat(chAthlete2.currentIndex >= 0 ? Plan.mazForAthlete(chAthlete2.currentValue) : [])
                    textRole: "displayName"
                    valueRole: "id"
                    onActivated: chartTab.reload()
                }
            }
            TrendChart {
                id: analysisChart
                documentTitle: "Grafik TÜ " + chEx.text
                Layout.fillWidth: true
                Layout.fillHeight: true
                labels: chartTab.first.labels || []
                showValues: chValues.checked
                leftTitle: chZiel.checked || chWk.checked ? "Intensität [%]" : "Intensität [kg]"
                rightTitle: "Umfang [Wh]"
                lines: {
                    const l = []
                    const two = chCompare.checked && chartTab.second.labels
                    const n1 = two ? " 1" : "", n2 = " 2"
                    if (chMhg.checked) l.push({ name: "MHG" + n1, color: Theme.ink, values: chartTab.first.mhg || [], trend: chTrend.checked })
                    if (chBw.checked) l.push({ name: "BW" + n1, color: Theme.accent, values: chartTab.first.bw || [], trend: chTrend.checked })
                    if (two && chMhg.checked) l.push({ name: "MHG" + n2, color: Theme.blue, values: chartTab.second.mhg || [], trend: chTrend.checked })
                    if (two && chBw.checked) l.push({ name: "BW" + n2, color: Theme.green, values: chartTab.second.bw || [], trend: chTrend.checked })
                    return l
                }
                bars: {
                    const b = []
                    if (chVolume.currentIndex > 0) {
                        b.push({ name: chVolume.currentText, color: Theme.slate, values: chartTab.first.wh || [] })
                        if (chCompare.checked && chartTab.second.wh)
                            b.push({ name: chVolume.currentText + " 2", color: "#93c5fd", values: chartTab.second.wh })
                    }
                    return b
                }
            }
        }
    }
}
