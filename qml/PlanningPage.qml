import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Long-term planning: macrocycles (MAZ), the framework plan of a MAZ (RO)
// and the individual training plan of an athlete (ITP).
Page {
    id: page

    // The framework plan (Rahmenorientierung) of a MAZ is shown, opened
    // from the MAZ as in WinWoTA; otherwise the tabs are the athlete's
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
    // Plan.mazList (notified on every change of the plans) makes the
    // athlete's list follow changes too; a call alone is read once
    readonly property var mazChoices: roMode ? Plan.mazList
                                             : (athleteId !== "" ? (Plan.mazList, Plan.mazForAthlete(athleteId)) : [])

    // For start options: "maz", "itp", "ro", "laststufen"
    function showTab(name) {
        if (name === "ro") {
            openFramework(roMazId)
            return
        }
        roMode = false
        tabs.currentIndex = name === "itp" ? 1 : name === "laststufen" ? 2 : 0
    }

    // The framework plan of a MAZ ("" = the one chosen last), in its own
    // view with a way back to the MAZ
    function openFramework(id) {
        roMode = true
        roTabs.currentIndex = 0
        if (id !== "")
            chooseMaz(id)
    }

    function closeFramework() {
        roMode = false
        tabs.currentIndex = 0
    }

    // The period chosen for ITP and for RO, kept apart, so switching
    // between them comes back to what was chosen: for ITP a MAZ of the
    // athlete or "" (own range), for RO a MAZ
    property string itpMazId: ""
    property bool itpMazChosen: false
    property string roMazId: ""

    function chooseMaz(id) {
        mazId = id
        if (roMode) {
            roMazId = id
        } else {
            itpMazId = id
            itpMazChosen = true
        }
    }

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true

    function selectDefaults() {
        if (choosesAthlete && athleteId === "" && Store.selectableAthletes.length > 0)
            athleteId = Store.selectableAthletes[0].id
        // The mode's own choice; a MAZ no longer there (or not the
        // athlete's) gives way to the first one, an own range chosen for
        // ITP stays
        let id = roMode ? roMazId : itpMazId
        const ownRange = !roMode && itpMazChosen && id === ""
        if (id !== "" && !mazChoices.some(m => m.id === id))
            id = ""
        if (id === "" && !ownRange && mazChoices.length > 0)
            id = mazChoices[0].id
        mazId = id
    }

    onRoModeChanged: selectDefaults()
    onMazChoicesChanged: selectDefaults()
    onAthleteIdChanged: selectDefaults()
    Component.onCompleted: selectDefaults()
    // The grid reloads only while it shows: reloading updates every cell,
    // half a second for a year's plan, and a hidden one would make each
    // save elsewhere (a target in the MAZ) wait for it. Hidden, it only
    // notes the change and reloads when it shows again.
    property bool itpStale: false
    Connections {
        target: Plan
        function onChanged() {
            page.reloadSteps()
            if (itpGrid.visible)
                itpGrid.model.reload()
            else
                page.itpStale = true
        }
    }
    Connections {
        target: itpGrid
        function onVisibleChanged() {
            if (itpGrid.visible && page.itpStale) {
                page.itpStale = false
                itpGrid.model.reload()
            }
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
                objectName: "planningTabs"
                visible: !page.roMode
                Layout.preferredWidth: 420
                AppTabButton { text: "MAZ" }
                AppTabButton { text: "ITP" }
                AppTabButton { text: "Laststufen" }
            }
            // The framework plan, opened from a MAZ: back to it, and its
            // two views
            IconButton {
                objectName: "backToMaz"
                visible: page.roMode
                iconName: "chevron-left"
                text: "MAZ"
                toolTip: "Zurück zum MAZ"
                onClicked: page.closeFramework()
            }
            Label {
                visible: page.roMode
                text: "Rahmenorientierung"
                font.bold: true
                Layout.leftMargin: 4
                Layout.rightMargin: 8
            }
            AppTabBar {
                id: roTabs
                objectName: "roTabs"
                visible: page.roMode
                Layout.preferredWidth: 280
                AppTabButton { text: "Werte" }
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

        // Whose plan: the athlete and one of their MAZ (ITP), or a MAZ (RO)
        RowLayout {
            visible: page.roMode || tabs.currentIndex > 0
            spacing: 8
            ValueComboBox {
                visible: !page.roMode
                implicitWidth: 200
                model: Store.selectableAthletes
                value: page.athleteId
                onChosen: (v) => page.athleteId = v
            }
            ValueComboBox {
                id: mazBox
                objectName: "mazBox"
                implicitWidth: 260
                model: (page.roMode ? [] : [{ id: "", displayName: "eigener Zeitraum" }]).concat(page.mazChoices)
                value: page.mazId
                displayText: currentIndex < 0 ? "MAZ wählen" : currentText
                onChosen: (v) => page.chooseMaz(v)
            }
            Label { visible: page.maz === null && !page.roMode; text: "ab" }
            WeekField {
                visible: page.maz === null && !page.roMode
                text: Plan.weekLabel(page.ownFrom)
                onEditingFinished: if (monday !== "") page.ownFrom = monday
                onWeekPicked: (m) => page.ownFrom = m
            }
            SpinBox {
                visible: page.maz === null && !page.roMode
                from: 1; to: 104; editable: true
                value: page.ownWeeks
                onValueModified: page.ownWeeks = value
            }
            Label { visible: page.maz === null && !page.roMode; text: "Wochen" }
            Label {
                visible: page.maz !== null
                text: page.maz ? page.maz.from + " – " + page.maz.to + " (" + page.maz.weeks + " Wochen)" : ""
                color: Styles.TokenInterface.semantics.text_muted
            }
            Item { Layout.fillWidth: true }
        }

        StackLayout {
            currentIndex: page.roMode ? roTabs.currentIndex + 1 : tabs.currentIndex
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
                        color: Styles.TokenInterface.semantics.text_muted
                    }
                    IconButton {
                        iconName: "copy"
                        text: "Vorlage"
                        enabled: page.owner !== "" && page.weeks > 0
                        onClicked: templateDialog.open()
                    }
                    IconButton {
                        visible: !page.roMode
                        iconName: "chart-line"
                        text: "Grafik"
                        enabled: page.athleteId !== "" && page.weeks > 0
                        onClicked: loadChart.show(page.athleteId, page.fromMonday, page.mazId,
                                                  page.exercises.find(e => e > 0) || 1)
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
                        color: Styles.TokenInterface.semantics.text_muted
                    }
                }
                Label { id: stepsError; color: Styles.TokenInterface.semantics.danger_default; visible: text !== "" }
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
                            color: Styles.TokenInterface.semantics.text_muted
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
                checked: !(page.roMode || page.maz === null)
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
                                         .concat(otherAthlete.currentIndex >= 0 ? (Plan.mazList, Plan.mazForAthlete(otherAthlete.currentValue)) : [])
                    textRole: "displayName"
                    valueRole: "id"
                }
            }
            Label {
                text: "Die vorhandenen Werte im Zeitraum werden überschrieben."
                color: Styles.TokenInterface.semantics.danger_default
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

    // The ITP against the weeks done: the load chart
    LoadChartDialog {
        id: loadChart
        objectName: "loadChartDialog"
    }
}
