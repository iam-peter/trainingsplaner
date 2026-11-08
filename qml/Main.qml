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
                Layout.preferredWidth: 280
                TabButton { text: "Wochenplan" }
                TabButton { text: "Sportler" }
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                text: "Daten importieren…"
                onClicked: importDialog.open()
                ToolTip.visible: hovered
                ToolTip.text: "Datensicherung des alten Programms (winwotaxp.bak) einlesen"
            }
            ToolButton {
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
    }

    FileDialog {
        id: importDialog
        title: "Datensicherung importieren"
        nameFilters: ["Datensicherung (*.bak)", "Alle Dateien (*)"]
        onAccepted: {
            importResult.text = Store.importBak(selectedFile)
            importResult.open()
            weekPage.selectDefaultAthlete()
        }
    }

    Dialog {
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
        weekPage.start(startAthlete, startWeek, startSession)
    }
}
