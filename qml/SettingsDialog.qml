import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

Dialog {
    id: dialog
    title: "Einstellungen"
    modal: true
    anchors.centerIn: Overlay.overlay
    standardButtons: Dialog.Save | Dialog.Cancel

    onAboutToShow: {
        trainerField.text = Store.trainer
        organisationField.text = Store.organisation
    }
    onAccepted: {
        Store.trainer = trainerField.text.trim()
        Store.organisation = organisationField.text.trim()
    }

    GridLayout {
        columns: 2
        columnSpacing: 12
        rowSpacing: 8

        Label {
            Layout.columnSpan: 2
            text: "Ausdruck"
            font.bold: true
        }
        Label { text: "Trainer:" }
        TextField {
            id: trainerField
            Layout.preferredWidth: 320
        }
        Label { text: "Kopfzeile rechts:" }
        TextField {
            id: organisationField
            Layout.preferredWidth: 320
            placeholderText: "z.B. Verein"
        }

        Label {
            Layout.columnSpan: 2
            Layout.topMargin: 12
            text: "Datenbank"
            font.bold: true
        }
        Label { text: "Datei:" }
        TextField {
            Layout.preferredWidth: 320
            readOnly: true
            selectByMouse: true
            text: Store.databasePath
        }
        Label {
            Layout.columnSpan: 2
            Layout.preferredWidth: 440
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: palette.placeholderText
            text: "Alle Daten stehen in dieser einen Datei. Zur Sicherung das Programm schließen und die Datei kopieren."
        }
    }
}
