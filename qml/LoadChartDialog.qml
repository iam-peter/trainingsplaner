import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// "Belastungsverlauf": one exercise's weight and the reps of K1-7 over the
// weeks of the athlete's MAZ (or twelve weeks around a week), against the
// ITP's targets, with an ideal line and the table of the same numbers.
// Opened from the week, the ITP and Analyse.
AppDialog {
    id: dialog

    property string athleteId
    // The week it was opened from; its MAZ is chosen when there is one
    property string monday
    property string mazId
    property int exercise: 1
    property string reference: "kg"
    readonly property var mazChoices: athleteId !== "" ? (Plan.mazList, Plan.mazForAthlete(athleteId)) : []
    readonly property var maz: mazId !== "" ? Plan.maz(mazId) : null
    property var course: ({})

    function show(a, m, maz, ex) {
        athleteId = a
        monday = m || Store.mondayOf(Store.today())
        exercise = ex > 0 ? ex : exercise
        let id = maz || ""
        if (id === "") {
            for (const z of mazChoices)
                if (z.fromMonday <= monday && monday <= Store.addWeeks(z.fromMonday, z.weeks - 1))
                    id = z.id
        }
        mazId = id
        if (mazId === "")
            reference = "kg"
        open()
        reload()
    }

    function reload() {
        if (!opened && !visible)
            return
        course = Plan.loadCourse(athleteId, mazId, Store.addWeeks(monday, -8), 12, exercise,
                                 mazId !== "" ? reference : "kg")
    }
    onMazIdChanged: reload()
    onExerciseChanged: reload()
    onReferenceChanged: reload()
    Connections {
        target: Store
        function onDataVersionChanged() { dialog.reload() }
    }
    Connections {
        target: Plan
        function onChanged() { dialog.reload() }
    }

    readonly property string athleteName: (Store.athletes.find(a => a.id === athleteId) || { displayName: "" }).displayName
    title: "Belastungsverlauf" + (athleteName !== "" ? " – " + athleteName : "")
    width: parent ? Math.min(parent.width - 40, 1200) : 1100
    height: parent ? Math.min(parent.height - 40, 860) : 800
    standardButtons: Dialog.Close

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label { text: "Übung:" }
            RowLayout {
                spacing: -Styles.Primitives.stroke.thin
                TextField {
                    id: numberField
                    objectName: "exerciseField"
                    groupPosition: Styles.GroupStyle.Position.First
                    implicitWidth: 46
                    horizontalAlignment: TextInput.AlignHCenter
                    font.bold: true
                    validator: IntValidator { bottom: 1; top: 99 }
                    text: dialog.exercise
                    onEditingFinished: {
                        const n = parseInt(text) || 0
                        // Only exercises with weights have a weight to show
                        if (Store.catalog.some(e => e.id === n && !e.text))
                            dialog.exercise = n
                        else
                            text = dialog.exercise
                    }
                }
                IconButton {
                    implicitHeight: numberField.height
                    groupPosition: Styles.GroupStyle.Position.Last
                    iconName: "layout-grid"
                    toolTip: "Übung auswählen"
                    onClicked: picker.open()
                    ExercisePicker {
                        id: picker
                        y: parent.height + 2
                        textExercises: false
                        current: dialog.exercise
                        onPicked: (id) => dialog.exercise = id
                    }
                }
            }
            Label {
                text: Store.exerciseName(dialog.exercise)
                font.bold: true
            }
            ToolSeparator {}
            ValueComboBox {
                id: mazBox
                objectName: "mazBox"
                implicitWidth: 260
                model: [{ id: "", displayName: "12 Wochen um die Woche" }].concat(dialog.mazChoices)
                value: dialog.mazId
                onChosen: (v) => dialog.mazId = v
            }
            ToolSeparator {}
            Label { text: "Gewichte:" }
            RadioButton {
                objectName: "referenceKg"
                text: "kg"
                checked: dialog.reference === "kg" || dialog.mazId === ""
                onToggled: if (checked) dialog.reference = "kg"
            }
            RadioButton {
                objectName: "referenceTarget"
                text: "% MAZ-Ziel"
                enabled: dialog.mazId !== ""
                checked: dialog.reference === "ziel" && dialog.mazId !== ""
                onToggled: if (checked) dialog.reference = "ziel"
            }
            RadioButton {
                text: "% MAZ-WK"
                enabled: dialog.mazId !== ""
                checked: dialog.reference === "wk" && dialog.mazId !== ""
                onToggled: if (checked) dialog.reference = "wk"
            }
            Item { Layout.fillWidth: true }
            CheckBox {
                id: tableBox
                objectName: "tableBox"
                text: "Tabelle"
            }
        }

        LoadChart {
            id: chart
            objectName: "loadChart"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 320
            course: dialog.course
        }

        // What the lines mean
        Flow {
            Layout.fillWidth: true
            spacing: 18
            Repeater {
                model: [
                    { text: "BW Ist", color: chart.bwColor, style: "solid" },
                    { text: "BW Ziel (ITP)", color: chart.bwColor, style: "dash" },
                    { text: "MHG Ist", color: chart.mhgColor, style: "solid" },
                    { text: "MHG Ziel (ITP)", color: chart.mhgColor, style: "dash" },
                    { text: "Ideallinie: vom ersten Ist zum letzten Ziel", color: "#888888", style: "dot" },
                    { text: "dünn: geplante Wochen", color: "#888888", style: "thin" },
                    { text: "Balken: WH K1-7 Ziel in h / m / g, Punkte: Ist", color: "#5b6b7f", style: "bar" },
                    { text: "schattiert: gesenkte Woche", color: "#b8c6d6", style: "bar" }
                ]
                Row {
                    required property var modelData
                    spacing: 6
                    Canvas {
                        width: 26
                        height: 12
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = modelData.color
                            ctx.fillStyle = modelData.color
                            if (modelData.style === "bar") {
                                ctx.fillRect(6, 1, 14, 10)
                                return
                            }
                            ctx.lineWidth = modelData.style === "solid" ? 2.5 : modelData.style === "thin" ? 1.2 : 1.6
                            ctx.setLineDash(modelData.style === "dash" ? [5, 3] : modelData.style === "dot" ? [1.5, 3] : [])
                            ctx.beginPath(); ctx.moveTo(0, 6); ctx.lineTo(26, 6); ctx.stroke()
                        }
                    }
                    Label { text: modelData.text; font.pixelSize: 11 }
                }
            }
        }

        // The same numbers, to read exactly, copy and print
        RowLayout {
            visible: tableBox.checked
            Layout.fillWidth: true
            spacing: 6
            Item { Layout.fillWidth: true }
            IconButton { iconName: "copy"; text: "Kopieren"; onClicked: table.copyTables() }
            IconButton { iconName: "printer"; text: "Drucken"; onClicked: table.printReport() }
        }
        ReportView {
            id: table
            objectName: "loadTable"
            visible: tableBox.checked
            Layout.fillWidth: true
            // Below the chart, which keeps the room
            Layout.fillHeight: false
            Layout.preferredHeight: 220
            Layout.maximumHeight: 220
            request: dialog.course
            build: (c) => c.report || {}
            emptyText: "Keine Wochen."
        }
    }
}
