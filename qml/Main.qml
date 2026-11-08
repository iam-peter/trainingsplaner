import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

ApplicationWindow {
    id: window

    // Set from the command line (see main.cpp).
    property string startAthlete
    property string startWeek
    property string startPage
    property string startSession

    width: 1366
    height: 900
    minimumWidth: 1000
    minimumHeight: 680
    visible: true
    title: "Trainingsplaner Gewichtheben"

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 8

            TabBar {
                id: tabs
                Layout.preferredWidth: 720
                TabButton {
                    text: "Wochenplan"
                    icon.source: "qrc:/qt/qml/Trainingsplaner/icons/calendar-days.svg"
                    icon.color: palette.buttonText
                    icon.width: 16
                    icon.height: 16
                }
                TabButton {
                    text: "Sportler"
                    icon.source: "qrc:/qt/qml/Trainingsplaner/icons/users.svg"
                    icon.color: palette.buttonText
                    icon.width: 16
                    icon.height: 16
                }
                TabButton {
                    text: "Planung"
                    icon.source: "qrc:/qt/qml/Trainingsplaner/icons/target.svg"
                    icon.color: palette.buttonText
                    icon.width: 16
                    icon.height: 16
                }
                TabButton {
                    text: "Analyse"
                    icon.source: "qrc:/qt/qml/Trainingsplaner/icons/chart-line.svg"
                    icon.color: palette.buttonText
                    icon.width: 16
                    icon.height: 16
                }
                TabButton {
                    text: "Wettkämpfe"
                    icon.source: "qrc:/qt/qml/Trainingsplaner/icons/trophy.svg"
                    icon.color: palette.buttonText
                    icon.width: 16
                    icon.height: 16
                }
            }

            Item { Layout.fillWidth: true }

            IconToolButton {
                id: dataButton
                iconName: "database"
                text: "Daten"
                onClicked: dataMenu.open()
                Menu {
                    id: dataMenu
                    y: dataButton.height
                    MenuItem {
                        text: "Importieren…"
                        icon.source: "qrc:/qt/qml/Trainingsplaner/icons/import.svg"
                        icon.color: palette.text
                        onTriggered: importDialog.open()
                    }
                    MenuItem {
                        text: "Exportieren…"
                        icon.source: "qrc:/qt/qml/Trainingsplaner/icons/file-down.svg"
                        icon.color: palette.text
                        onTriggered: exportDialog.open()
                    }
                }
            }
            IconToolButton {
                iconName: "settings"
                text: "Einstellungen"
                onClicked: settingsDialog.open()
            }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: tabs.currentIndex

        WeekPage {
            id: weekPage
        }

        AthletesPage {
            onOpenWeekPlan: (athleteId) => {
                weekPage.athleteId = athleteId
                tabs.currentIndex = 0
            }
        }

        PlanningPage {
            id: planningPage
        }

        AnalysisPage {
            id: analysisPage
        }

        CompetitionsPage {
            id: competitionsPage
        }
    }

    FileDialog {
        id: importDialog
        title: "Datensicherung importieren"
        nameFilters: ["Datensicherung (*.bak)", "Alle Dateien (*)"]
        onAccepted: importOptions.open()
    }

    AppDialog {
        id: importOptions
        title: "Daten importieren"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel
        ColumnLayout {
            Label {
                text: decodeURIComponent(importDialog.selectedFile.toString().replace(/^.*\//, ""))
                font.bold: true
            }
            Label {
                text: "Neuere Einträge im Programm bleiben erhalten."
                color: palette.placeholderText
            }
            CheckBox {
                id: ignoreTimestamps
                text: "Zeitstempel nicht berücksichtigen (Datei überschreibt alles)"
            }
        }
        onAccepted: {
            importResult.text = Store.importBak(importDialog.selectedFile, ignoreTimestamps.checked)
            ignoreTimestamps.checked = false
            importResult.open()
            weekPage.selectDefaultAthlete()
        }
    }

    ExportDialog {
        id: exportDialog
    }

    AppDialog {
        id: importResult
        property alias text: resultLabel.text
        title: "Import abgeschlossen"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
        Label {
            id: resultLabel
        }
    }

    SettingsDialog {
        id: settingsDialog
    }

    Component.onCompleted: {
        if (startPage === "sportler")
            tabs.currentIndex = 1
        if (startPage === "planung") {
            tabs.currentIndex = 2
            if (startAthlete !== "")
                planningPage.athleteId = startAthlete
            planningPage.showTab(startSession)
        }
        if (startPage === "analyse") {
            tabs.currentIndex = 3
            if (startAthlete !== "")
                analysisPage.athleteId = startAthlete
            Qt.callLater(analysisPage.show, startSession)
        }
        if (startPage === "wettkaempfe") {
            tabs.currentIndex = 4
            if (startAthlete !== "")
                competitionsPage.athleteId = startAthlete
            if (startSession === "grafik")
                competitionsPage.showChart()
        }
        if (startPage === "einstellungen")
            Qt.callLater(settingsDialog.open)
        weekPage.start(startAthlete, startWeek, startPage === "" || startPage === "plan" ? startSession : "")
    }
}
