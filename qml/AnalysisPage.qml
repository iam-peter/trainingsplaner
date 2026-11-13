import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Analyses: section analysis of an athlete, group analysis of a MAZ, data
// check, and charts.
Page {
    id: page

    property string athleteId

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true

    function selectDefaultAthlete() {
        if (choosesAthlete && athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
    }
    Component.onCompleted: selectDefaultAthlete()

    // For start options: "individual", "group", "check", "chart"
    function show(name) {
        tabs.currentIndex = ["individual", "group", "check", "chart"].indexOf(name) >= 0
                            ? ["individual", "group", "check", "chart"].indexOf(name) : 0
        if (tabs.currentIndex === 3) chartTab.reload()
    }

    // Plan.mazList is notified on every change of the plans, so the list
    // follows them (Plan.changed, a signal, made no dependency)
    readonly property var athleteMaz: athleteId !== "" ? (Plan.mazList, Plan.mazForAthlete(athleteId)) : []
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
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            AppTabBar {
                id: tabs
                objectName: "analysisTabs"
                Layout.preferredWidth: 560
                AppTabButton { text: "Individualanalyse" }
                AppTabButton { text: "Gruppenanalyse" }
                AppTabButton { text: "Datenprüfung" }
                AppTabButton { text: "Grafik" }
            }
            // The load over the cycle, against the ITP
            IconButton {
                objectName: "loadChartButton"
                iconName: "chart-line"
                text: "Belastungsverlauf"
                enabled: page.athleteId !== ""
                toolTip: "Gewicht und Wiederholungen über die Wochen des MAZ, gegen das ITP"
                onClicked: loadChart.show(page.athleteId, "", "", 1)
            }
            Item { Layout.fillWidth: true }
            // For what the tab shows: its report, or the chart
            IconButton {
                objectName: "copyButton"
                visible: page.report !== null
                enabled: page.report?.hasReport ?? false
                iconName: "copy"
                text: "Kopieren"
                toolTip: "Die Tabellen für eine Tabellenkalkulation kopieren"
                onClicked: page.report.copyTables()
            }
            IconButton {
                iconName: "printer"
                text: "Drucken"
                enabled: page.report === null || page.report.hasReport
                onClicked: page.report ? page.report.printReport() : analysisChart.printChart()
            }
            IconButton {
                objectName: "saveAsButton"
                iconName: "file-down"
                text: "Speichern unter"
                toolTip: page.report ? "Als PDF oder als CSV für eine Tabellenkalkulation" : "Die Grafik als PNG-Bild"
                enabled: page.report === null || page.report.hasReport
                onClicked: page.report ? page.report.saveAs() : analysisChart.saveImage()
            }
        }
    }

    LoadChartDialog {
        id: loadChart
        objectName: "loadChartDialog"
    }

    // The report of the tab shown, null on the chart
    readonly property ReportView report: [individualReport, groupReport, checkReport][tabs.currentIndex] ?? null

    StackLayout {
        anchors.fill: parent
        // Lined up with the toolbar above (8 px from the window edge)
        anchors.margins: 8
        currentIndex: tabs.currentIndex

        // Section analysis of one athlete
        RowLayout {
            spacing: 8
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
                    ValueComboBox {
                        Layout.fillWidth: true
                        model: Store.selectableAthletes
                        value: page.athleteId
                        onChosen: (v) => page.athleteId = v
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
                        spacing: 8
                        visible: iMaz.currentIndex <= 0
                        Label { text: "ab" }
                        WeekField { id: iFrom; text: page.defaultFrom }
                        SpinBox { id: iWeeks; from: 1; to: 104; value: 12; editable: true }
                        Label { text: "Wochen" }
                    }
                    CheckBox { id: iCompWeeks; text: "WK-Woche einschließen" }
                    Label { text: "Bezug"; font.bold: true }
                    RowLayout {
                        spacing: 8
                        RadioButton { id: iIst; text: "Ist"; checked: true }
                        RadioButton { id: iPlan; text: "Plan" }
                        RadioButton { id: iItp; text: "ITP" }
                    }
                    RowLayout {
                        spacing: 8
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
                        spacing: 8
                        CheckBox { id: iLoad; text: "Laststufenanalyse TÜ" }
                        TextField { id: iLoadEx; implicitWidth: 44; text: "1"; enabled: iLoad.checked; validator: IntValidator { bottom: 1; top: 45 } }
                    }
                }
            }
            ReportView {
                id: individualReport
                objectName: "individualReport"
                Layout.fillWidth: true
                Layout.fillHeight: true
                request: page.athleteId !== "" ? page.individualParams() : null
                build: (p) => Analysis.individual(p)
                ready: iMaz.currentIndex > 0 || iFrom.monday !== ""
                emptyText: "Bitte einen Sportler wählen."
            }
        }

        // Group analysis of a MAZ
        RowLayout {
            spacing: 8
            ColumnLayout {
                // As wide as the settings of the other tabs: a layout would
                // otherwise share the width with the report
                Layout.fillWidth: false
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
                    spacing: 8
                    enabled: gIntensity.checked
                    Label { text: "TÜ" }
                    TextField { id: gExercise; implicitWidth: 44; text: "1"; validator: IntValidator { bottom: 1; top: 45 } }
                    Label { text: Store.exerciseName(parseInt(gExercise.text) || 0); color: Styles.TokenInterface.semantics.text_muted }
                }
                RowLayout {
                    spacing: 8
                    enabled: gIntensity.checked
                    RadioButton { id: gKg; text: "kg"; checked: true }
                    RadioButton { id: gZiel; text: "% MAZ-Ziel" }
                    RadioButton { id: gWk; text: "% MAZ-WK" }
                }
                CheckBox { id: gCompWeeks; text: "WK-Woche einschließen" }
            }
            ReportView {
                id: groupReport
                objectName: "groupReport"
                Layout.fillWidth: true
                Layout.fillHeight: true
                request: gMaz.currentIndex >= 0 ? {
                    mazId: gMaz.currentValue, mode: gVolume.checked ? 1 : gIntensity.checked ? 2 : 0,
                    exercise: parseInt(gExercise.text) || 1,
                    reference: gZiel.checked ? "ziel" : gWk.checked ? "wk" : "kg",
                    competitionWeeks: gCompWeeks.checked
                } : null
                build: (p) => Analysis.group(p)
                emptyText: "Bitte zuerst einen MAZ anlegen."
            }
        }

        // Which athletes have data
        RowLayout {
            spacing: 8
            ColumnLayout {
                // As wide as the settings of the other tabs: a layout would
                // otherwise share the width with the report
                Layout.fillWidth: false
                Layout.preferredWidth: 330
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Label { text: "Zeitraum"; font.bold: true }
                RowLayout {
                    spacing: 8
                    Label { text: "ab" }
                    WeekField { id: cFrom; text: page.defaultFrom }
                    SpinBox { id: cWeeks; from: 1; to: 104; value: 12; editable: true }
                    Label { text: "Wochen" }
                }
                RadioButton { id: cTraining; text: "Trainingsdaten"; checked: true }
                RadioButton { text: "Wettkämpfe" }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: Styles.TokenInterface.semantics.text_muted
                    text: "Alle Sportler der Auswahl aus den Einstellungen (Kader, Männer/Frauen)."
                }
            }
            ReportView {
                id: checkReport
                objectName: "checkReport"
                Layout.fillWidth: true
                Layout.fillHeight: true
                request: ({
                    from: cFrom.text, weeks: cWeeks.value, mode: cTraining.checked ? 0 : 1,
                    athletes: Store.selectableAthletes
                })
                build: (p) => Analysis.dataCheck(p)
                ready: cFrom.monday !== ""
            }
        }

        // Charts
        ColumnLayout {
            id: chartTab
            objectName: "chartTab"
            spacing: 8
            property var first: ({})
            property var second: ({})
            // Built when it shows, and again when the data or the athlete
            // change while it does; it was empty until a setting changed
            onVisibleChanged: if (visible) reload()
            Connections {
                target: Store
                function onDataVersionChanged() { if (chartTab.visible) chartTab.reload() }
            }
            Connections {
                target: page
                function onAthleteIdChanged() { if (chartTab.visible) chartTab.reload() }
            }
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
                ValueComboBox {
                    implicitWidth: 180
                    model: Store.selectableAthletes
                    value: page.athleteId
                    // The chart follows the athlete (Connections above)
                    onChosen: (v) => page.athleteId = v
                }
                ComboBox {
                    id: chMaz
                    implicitWidth: 200
                    model: [{ id: "", displayName: "Wochen" }].concat(page.athleteMaz)
                    textRole: "displayName"
                    valueRole: "id"
                    onActivated: chartTab.reload()
                }
                WeekField { id: chFrom; visible: chMaz.currentIndex <= 0; text: page.defaultFrom; onEditingFinished: chartTab.reload(); onWeekPicked: chartTab.reload() }
                SpinBox { id: chWeeks; visible: chMaz.currentIndex <= 0; from: 2; to: 104; value: 12; editable: true; onValueModified: chartTab.reload() }
                Label { text: "TÜ" }
                TextField {
                    id: chEx
                    implicitWidth: 44
                    text: "1"
                    validator: IntValidator { bottom: 1; top: 45 }
                    onEditingFinished: chartTab.reload()
                }
                Label { text: Store.exerciseName(parseInt(chEx.text) || 0); color: Styles.TokenInterface.semantics.text_muted }
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
                    model: [{ id: "", displayName: "gleiche Wochen" }].concat(chAthlete2.currentIndex >= 0 ? (Plan.mazList, Plan.mazForAthlete(chAthlete2.currentValue)) : [])
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
                    if (chMhg.checked) l.push({ name: "MHG" + n1, color: Styles.TokenInterface.semantics.chart_series[1], values: chartTab.first.mhg || [], trend: chTrend.checked })
                    if (chBw.checked) l.push({ name: "BW" + n1, color: Styles.TokenInterface.semantics.primary_default, values: chartTab.first.bw || [], trend: chTrend.checked })
                    if (two && chMhg.checked) l.push({ name: "MHG" + n2, color: Styles.TokenInterface.semantics.chart_series[2], values: chartTab.second.mhg || [], trend: chTrend.checked })
                    if (two && chBw.checked) l.push({ name: "BW" + n2, color: Styles.TokenInterface.semantics.chart_series[3], values: chartTab.second.bw || [], trend: chTrend.checked })
                    return l
                }
                bars: {
                    const b = []
                    if (chVolume.currentIndex > 0) {
                        b.push({ name: chVolume.currentText, color: Styles.TokenInterface.semantics.chart_muted, values: chartTab.first.wh || [] })
                        if (chCompare.checked && chartTab.second.wh)
                            b.push({ name: chVolume.currentText + " 2", color: "#93c5fd", values: chartTab.second.wh })
                    }
                    return b
                }
            }
        }
    }
}
