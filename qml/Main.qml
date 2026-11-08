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

    // The athlete all pages show: choosing one on any page selects them on
    // the others too
    property string athlete

    width: 1366
    height: 900
    minimumWidth: 1000
    minimumHeight: 680
    visible: true
    title: "Trainingsplaner Gewichtheben"

    // The controls take the application palette, so a palette set by the
    // program (--farbschema) reaches them as well as the system's
    palette.window: Theme.system.window
    palette.windowText: Theme.system.windowText
    palette.base: Theme.system.base
    palette.alternateBase: Theme.system.alternateBase
    palette.text: Theme.system.text
    palette.button: Theme.system.button
    palette.buttonText: Theme.system.buttonText
    palette.highlight: Theme.system.highlight
    palette.highlightedText: Theme.system.highlightedText
    palette.placeholderText: Theme.system.placeholderText
    palette.mid: Theme.system.mid
    palette.dark: Theme.system.dark
    palette.light: Theme.system.light
    palette.toolTipBase: Theme.system.toolTipBase
    palette.toolTipText: Theme.system.toolTipText

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
            objectName: "weekPage"
            onAthleteIdChanged: window.athlete = athleteId
        }

        AthletesPage {
            id: athletesPage
            objectName: "athletesPage"
            onSelectedIdChanged: if (selectedId !== "") window.athlete = selectedId
            // Follows the others only when shown and without unsaved edits
            onVisibleChanged: if (visible && !dirty && window.athlete !== "" && selectedId !== window.athlete)
                                  select(window.athlete)
            onOpenWeekPlan: (athleteId) => {
                window.athlete = athleteId
                tabs.currentIndex = 0
            }
        }

        PlanningPage {
            id: planningPage
            objectName: "planningPage"
            onAthleteIdChanged: window.athlete = athleteId
        }

        AnalysisPage {
            id: analysisPage
            objectName: "analysisPage"
            onAthleteIdChanged: window.athlete = athleteId
        }

        CompetitionsPage {
            id: competitionsPage
            objectName: "competitionsPage"
            onAthleteIdChanged: window.athlete = athleteId
        }
    }

    Binding { target: weekPage; property: "athleteId"; value: window.athlete }
    Binding { target: planningPage; property: "athleteId"; value: window.athlete }
    Binding { target: analysisPage; property: "athleteId"; value: window.athlete }
    Binding { target: competitionsPage; property: "athleteId"; value: window.athlete }

    FileDialog {
        id: importDialog
        title: "Datensicherung importieren"
        nameFilters: ["Datensicherung (*.bak)", "Alle Dateien (*)"]
        onAccepted: importOptions.open()
    }

    AppDialog {
        id: importOptions
        title: "Daten importieren"
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
        standardButtons: Dialog.Ok
        Label {
            id: resultLabel
        }
    }

    SettingsDialog {
        id: settingsDialog
    }

    Component.onCompleted: {
        if (startAthlete !== "")
            athlete = startAthlete
        if (startPage === "sportler")
            tabs.currentIndex = 1
        if (startPage === "planung") {
            tabs.currentIndex = 2
            planningPage.showTab(startSession)
        }
        if (startPage === "analyse") {
            tabs.currentIndex = 3
            Qt.callLater(analysisPage.show, startSession)
        }
        if (startPage === "wettkaempfe") {
            tabs.currentIndex = 4
            if (startSession === "grafik")
                competitionsPage.showChart()
        }
        if (startPage === "einstellungen")
            Qt.callLater(settingsDialog.open)
        weekPage.start(startAthlete, startWeek, startPage === "" || startPage === "plan" ? startSession : "")
    }
}
