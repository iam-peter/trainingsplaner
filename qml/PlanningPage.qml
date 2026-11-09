import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Long-term planning: macrocycles (MAZ), the framework plan of a MAZ (RO)
// and the individual training plan of an athlete (ITP).
Page {
    id: page

    // What the ITP/RO tabs show
    property bool roMode: false
    property string athleteId
    property string mazId          // "" = own range
    property string ownFrom: Store.mondayOf(Store.today())
    property int ownWeeks: 12
    property int setIndex: 0

    readonly property var maz: mazId !== "" ? Plan.maz(mazId) : null
    readonly property string owner: roMode ? (mazId !== "" ? Plan.roOwner(mazId) : "") : athleteId
    readonly property string fromMonday: maz ? maz.fromMonday : ownFrom
    readonly property int weeks: maz ? maz.weeks : ownWeeks
    readonly property var exercises: Plan.exerciseSets[setIndex].exercises
    readonly property var mazChoices: roMode ? Plan.mazList : (athleteId !== "" ? Plan.mazForAthlete(athleteId) : [])

    // For start options: "maz", "itp", "ro", "laststufen"
    function showTab(name) {
        if (name === "ro")
            roMode = true
        tabs.currentIndex = name === "itp" || name === "ro" ? 1 : name === "laststufen" ? 2 : 0
    }

    function openFramework(id) {
        roMode = true
        mazId = id
        tabs.currentIndex = 1
    }

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true

    function selectDefaults() {
        if (choosesAthlete && athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
        if (mazId !== "" && !mazChoices.some(m => m.id === mazId))
            mazId = ""
        if (mazId === "" && mazChoices.length > 0)
            mazId = mazChoices[0].id
    }

    onRoModeChanged: { mazId = ""; selectDefaults() }
    onAthleteIdChanged: selectDefaults()
    Component.onCompleted: selectDefaults()
    Connections {
        target: Plan
        function onChanged() { itpGrid.model.reload(); page.reloadSteps() }
    }

    header: AppToolBar {
        RowLayout {
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            AppTabBar {
                id: tabs
                Layout.preferredWidth: 420
                AppTabButton { text: "MAZ" }
                AppTabButton { text: "ITP / RO" }
                AppTabButton { text: "Laststufen" }
            }
            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        // Lined up with the toolbar above (8 px from the window edge)
        anchors.margins: 8
        spacing: 8

        // Selection for the ITP/RO tabs
        RowLayout {
            visible: tabs.currentIndex > 0
            spacing: 8
            RadioButton { text: "ITP"; checked: !page.roMode; onToggled: if (checked) page.roMode = false }
            RadioButton { text: "Rahmenorientierung"; checked: page.roMode; onToggled: if (checked) page.roMode = true }
            ComboBox {
                visible: !page.roMode
                implicitWidth: 200
                model: Store.selectableAthletes
                textRole: "displayName"
                valueRole: "id"
                currentIndex: indexOfValue(page.athleteId)
                onActivated: page.athleteId = currentValue
            }
            ComboBox {
                id: mazBox
                implicitWidth: 260
                model: (page.roMode ? [] : [{ id: "", displayName: "eigener Zeitraum" }]).concat(page.mazChoices)
                textRole: "displayName"
                valueRole: "id"
                currentIndex: indexOfValue(page.mazId)
                displayText: currentIndex < 0 ? (page.roMode ? "MAZ wählen" : "eigener Zeitraum") : currentText
                onActivated: page.mazId = currentValue
            }
            Label { visible: page.maz === null && !page.roMode; text: "ab" }
            TextField {
                visible: page.maz === null && !page.roMode
                implicitWidth: 80
                text: Plan.weekLabel(page.ownFrom)
                onEditingFinished: { const m = Plan.mondayFromLabel(text); if (m !== "") page.ownFrom = m }
            }
            SpinBox {
                visible: page.maz === null && !page.roMode
                from: 1; to: 104; value: page.ownWeeks; editable: true
                onValueModified: page.ownWeeks = value
            }
            Label { visible: page.maz === null && !page.roMode; text: "Wochen" }
            Label {
                visible: page.maz !== null
                text: page.maz ? page.maz.from + " – " + page.maz.to + " (" + page.maz.weeks + " Wochen)" : ""
                color: palette.placeholderText
            }
            Item { Layout.fillWidth: true }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            MazPane {
                objectName: "mazPane"
                onOpenFramework: (id) => page.openFramework(id)
            }

            // Week targets
            ColumnLayout {
                spacing: 8
                RowLayout {
                    spacing: 8
                    ComboBox {
                        implicitWidth: 340
                        model: Plan.exerciseSets.map(s => s.name)
                        currentIndex: page.setIndex
                        onActivated: page.setIndex = currentIndex
                    }
                    CheckBox { id: averageAll; text: "Durchschnitt über alle Wochen" }
                    Item { Layout.fillWidth: true }
                    Label {
                        visible: page.roMode
                        text: "MHG und BW in % der Zielleistung"
                        color: palette.placeholderText
                    }
                    IconButton {
                        iconName: "copy"
                        text: "Vorlage…"
                        enabled: page.owner !== "" && page.weeks > 0
                        onClicked: templateDialog.open()
                    }
                    IconButton {
                        visible: !page.roMode
                        iconName: "chart-line"
                        text: "Grafik…"
                        enabled: page.athleteId !== "" && page.weeks > 0
                        onClicked: chartDialog.open()
                    }
                }
                ItpGrid {
                    id: itpGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    owner: page.owner
                    fromMonday: page.fromMonday
                    weeks: page.owner !== "" ? page.weeks : 0
                    exercises: page.exercises
                    mazId: page.mazId
                    averageAllWeeks: averageAll.checked
                }
            }

            // Planned weight steps of one exercise
            ColumnLayout {
                spacing: 8
                RowLayout {
                    spacing: 8
                    Label { text: "Übung:" }
                    TextField {
                        id: stepsExercise
                        implicitWidth: 50
                        text: "1"
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 1; top: 45 }
                        onEditingFinished: page.reloadSteps()
                    }
                    IconButton {
                        iconName: "layout-grid"
                        toolTip: "Übung auswählen"
                        onClicked: stepsPicker.open()
                        ExercisePicker {
                            id: stepsPicker
                            y: parent.height + 2
                            current: parseInt(stepsExercise.text) || 0
                            onPicked: (id) => { stepsExercise.text = id; page.reloadSteps() }
                        }
                    }
                    Label { text: Store.exerciseName(parseInt(stepsExercise.text) || 0); font.bold: true }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: page.roMode ? "Gewicht in % der Zielleistung, z.B. 70/3/2 75/3/2"
                                          : "Laststufen als kg/Wdh/Sätze, z.B. 80/3/2 85/3/2"
                        color: palette.placeholderText
                    }
                }
                Label { id: stepsError; color: Theme.error; visible: text !== "" }
                ListView {
                    boundsBehavior: Flickable.StopAtBounds
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    // The form spacing between the rows of fields
                    spacing: 8
                    model: page.stepRows
                    ScrollBar.vertical: AppScrollBar {}
                    delegate: RowLayout {
                        required property var modelData
                        width: ListView.view.width - (ListView.view.ScrollBar.vertical?.room ?? 0)
                        spacing: 8
                        Label { text: modelData.label; Layout.preferredWidth: 80 }
                        TextField {
                            Layout.fillWidth: true
                            text: modelData.text
                            font.family: "JetBrains Mono"
                            onEditingFinished: {
                                if (text === modelData.text)
                                    return
                                stepsError.text = Plan.setPlannedSteps(page.owner, parseInt(stepsExercise.text) || 0,
                                                                       modelData.monday, text)
                            }
                        }
                        Label {
                            Layout.preferredWidth: 220
                            text: modelData.wh > 0 ? "WH " + modelData.wh + "   MHG " + modelData.mhg + "   BW " + modelData.bw : ""
                            color: palette.placeholderText
                        }
                    }
                }
            }
        }
    }

    property var stepRows: []
    function reloadSteps() {
        stepRows = owner !== "" && weeks > 0
                   ? Plan.plannedSteps(owner, parseInt(stepsExercise.text) || 0, fromMonday, weeks) : []
    }
    onOwnerChanged: reloadSteps()
    onFromMondayChanged: reloadSteps()
    onWeeksChanged: reloadSteps()

    // Template: RO of the MAZ, or another athlete's / MAZ's plan
    AppDialog {
        id: templateDialog
        title: "Vorlage übernehmen"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAboutToShow: fromRo.checked = !page.roMode && page.maz !== null
        ColumnLayout {
            spacing: 8
            RadioButton {
                id: fromRo
                visible: !page.roMode
                enabled: page.maz !== null
                text: "Rahmenorientierung des MAZ (Prozente mit den Zielleistungen umgerechnet)"
            }
            RadioButton {
                id: fromOther
                checked: page.roMode || page.maz === null
                text: page.roMode ? "Rahmenorientierung eines anderen MAZ" : "ITP eines anderen Sportlers"
            }
            RowLayout {
                spacing: 8
                enabled: fromOther.checked
                Layout.leftMargin: 24
                ComboBox {
                    id: otherAthlete
                    visible: !page.roMode
                    implicitWidth: 200
                    model: Store.selectableAthletes.filter(a => a.id !== page.athleteId)
                    textRole: "displayName"
                    valueRole: "id"
                }
                ComboBox {
                    id: otherMaz
                    implicitWidth: 260
                    model: page.roMode ? Plan.mazList.filter(m => m.id !== page.mazId)
                                       : [{ id: "", displayName: "gleicher Zeitraum", fromMonday: page.fromMonday, weeks: page.weeks }]
                                         .concat(otherAthlete.currentIndex >= 0 ? Plan.mazForAthlete(otherAthlete.currentValue) : [])
                    textRole: "displayName"
                    valueRole: "id"
                }
            }
            Label {
                text: "Die vorhandenen Werte im Zeitraum werden überschrieben."
                color: Theme.error
            }
        }
        onAccepted: {
            if (fromRo.checked && page.maz) {
                Plan.itpFromRo(page.mazId, page.athleteId)
                return
            }
            const src = otherMaz.model[otherMaz.currentIndex]
            if (!src)
                return
            const fromOwner = page.roMode ? Plan.roOwner(src.id) : otherAthlete.currentValue
            Plan.copyPlan(fromOwner, src.fromMonday, page.owner, page.fromMonday, Math.min(src.weeks, page.weeks))
        }
    }

    // ITP against the week plans
    AppDialog {
        id: chartDialog
        title: "ITP und Trainingswochen"
        width: Math.min(parent ? parent.width - 60 : 900, 1000)
        height: Math.min(parent ? parent.height - 60 : 640, 680)
        standardButtons: Dialog.Close
        property var chartData: ({})
        function reload() {
            chartData = Plan.comparison(page.athleteId, page.fromMonday, page.weeks,
                                   page.exercises[chartExercise.currentIndex] || 1, chartIst.checked ? "I" : "P")
        }
        onAboutToShow: reload()
        contentItem: ColumnLayout {
            spacing: 8
            RowLayout {
                spacing: 8
                ComboBox {
                    id: chartExercise
                    implicitWidth: 260
                    model: page.exercises.map(e => e < 0 ? "Komplex K" + (-e) : e + "  " + Store.exerciseName(e))
                    onActivated: chartDialog.reload()
                }
                RadioButton { text: "Plan"; checked: true; onToggled: chartDialog.reload() }
                RadioButton { id: chartIst; text: "Ist"; onToggled: chartDialog.reload() }
                Item { Layout.fillWidth: true }
                IconButton {
                    iconName: "file-down"
                    text: "Bild…"
                    toolTip: "Grafik als PNG-Bild speichern"
                    onClicked: comparisonChart.saveImage()
                }
                IconButton {
                    iconName: "printer"
                    text: "Drucken…"
                    onClicked: comparisonChart.printChart()
                }
            }
            TrendChart {
                id: comparisonChart
                documentTitle: chartDialog.title
                Layout.fillWidth: true
                Layout.fillHeight: true
                labels: chartDialog.chartData.labels || []
                leftTitle: "Intensität [kg]"
                rightTitle: "Umfang [Wh]"
                lines: [
                    { name: "MHG ITP", color: "#a8a29e", values: chartDialog.chartData.itpMhg || [] },
                    { name: "BW ITP", color: "#fdba74", values: chartDialog.chartData.itpBw || [] },
                    { name: "MHG " + (chartIst.checked ? "Ist" : "Plan"), color: Theme.ink, values: chartDialog.chartData.actMhg || [] },
                    { name: "BW " + (chartIst.checked ? "Ist" : "Plan"), color: Theme.accent, values: chartDialog.chartData.actBw || [] }
                ]
                bars: [
                    { name: "WH ITP", color: "#cbd5e1", values: chartDialog.chartData.itpWh || [] },
                    { name: "WH " + (chartIst.checked ? "Ist" : "Plan"), color: Theme.slate, values: chartDialog.chartData.actWh || [] }
                ]
            }
        }
    }
}
