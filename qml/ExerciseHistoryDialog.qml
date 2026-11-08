import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Earlier uses of an exercise (Infofenster) and its trend over the last
// weeks (Grafik), as the old program showed them from the session editor.
AppDialog {
    id: dialog

    property string athleteId
    property string monday
    property string variant: "P"
    property int exercise: 0
    property var history: []
    property var trend: ({})

    function show(a, m, v, ex, chart) {
        athleteId = a
        monday = m
        variant = v
        exercise = ex
        tabs.currentIndex = chart ? 1 : 0
        reload()
        open()
    }

    function reload() {
        history = Store.exerciseHistory(athleteId, monday, variant, exercise, weeksBox.value)
        trend = Store.exerciseTrend(athleteId, monday, variant, exercise, weeksBox.value)
    }

    title: "TÜ " + exercise + "  " + Store.exerciseName(exercise) + "  –  bis Woche " + Store.weekLabel(monday)
           + "  (" + (variant === "P" ? "Plan" : "Ist") + ")"
    width: Math.min(parent ? parent.width - 60 : 900, 960)
    height: Math.min(parent ? parent.height - 60 : 640, 680)
    standardButtons: Dialog.Close

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            AppTabBar {
                id: tabs
                Layout.preferredWidth: 260
                AppTabButton { text: "Verlauf" }
                AppTabButton { text: "Grafik" }
            }
            Item { Layout.fillWidth: true }
            Label { text: "Wochen:" }
            SpinBox {
                id: weeksBox
                from: 2
                to: 104
                value: 10
                editable: true
                onValueModified: dialog.reload()
            }
            CheckBox { id: values; text: "Werte"; visible: tabs.currentIndex === 1 }
            IconButton {
                visible: tabs.currentIndex === 1
                iconName: "file-down"
                text: "Bild…"
                toolTip: "Grafik als PNG-Bild speichern"
                onClicked: chart.saveImage()
            }
            IconButton {
                visible: tabs.currentIndex === 1
                iconName: "printer"
                text: "Drucken…"
                onClicked: chart.printChart()
            }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Label { text: "Woche"; Layout.preferredWidth: 70; font.bold: true }
                    Label { text: "Tag"; Layout.preferredWidth: 190; font.bold: true }
                    Label { text: "BW"; Layout.preferredWidth: 60; font.bold: true }
                    Label { text: "MHG"; Layout.preferredWidth: 50; font.bold: true }
                    Label { text: "WH"; Layout.preferredWidth: 50; font.bold: true }
                    Label { text: "Laststufen"; Layout.fillWidth: true; font.bold: true }
                }
                ListView {
                    boundsBehavior: Flickable.StopAtBounds
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: dialog.history
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 26
                        color: index % 2 ? palette.alternateBase : palette.base
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            Label { text: modelData.week; Layout.preferredWidth: 70 }
                            Label { text: modelData.day + ", " + modelData.date; Layout.preferredWidth: 190 }
                            Label { text: modelData.bw + "  " + modelData.repsSets; Layout.preferredWidth: 60 }
                            Label { text: modelData.mhg; Layout.preferredWidth: 50 }
                            Label { text: modelData.wh; Layout.preferredWidth: 50 }
                            Label { text: modelData.steps; Layout.fillWidth: true; font.family: "JetBrains Mono"; elide: Text.ElideRight }
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: dialog.history.length === 0
                        text: "Die Übung kam in diesem Zeitraum nicht vor."
                        color: palette.placeholderText
                    }
                }
            }

            TrendChart {
                id: chart
                documentTitle: dialog.title
                labels: dialog.trend.labels || []
                showValues: values.checked
                leftTitle: "Intensität [kg]"
                rightTitle: "Umfang [Wh]"
                lines: [
                    { name: "MHG", color: Theme.ink, values: dialog.trend.mhg || [], trend: true },
                    { name: "BW", color: Theme.accent, values: dialog.trend.bw || [], trend: true }
                ]
                bars: [{ name: "WH", color: Theme.slate, values: dialog.trend.wh || [] }]
            }
        }
    }
}
