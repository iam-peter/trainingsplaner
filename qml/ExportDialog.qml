import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

// Data export in the old program's file format: everything, the changes
// since a point in time, or one athlete's weeks.
AppDialog {
    id: dialog
    title: "Daten exportieren"
    width: 560

    property string summary

    onAboutToShow: {
        summary = ""
        const last = Store.lastExport()
        if (last !== "") {
            sinceDate.text = last.split(" ")[0]
            sinceTime.text = last.split(" ")[1]
        } else {
            sinceDate.text = Store.formatDate(Store.today())
            sinceTime.text = "00:00"
        }
        const monday = Store.mondayOf(Store.today())
        fromWeek.text = Store.weekLabel(Store.addWeeks(monday, -3))
        toWeek.text = Store.weekLabel(monday)
        if (athleteBox.currentIndex < 0 && Store.athletes.length > 0)
            athleteBox.currentIndex = 0
    }

    contentItem: ColumnLayout {
        spacing: 8

        RadioButton { id: modeAll; text: "Alle Daten"; checked: true }

        RadioButton { id: modeSince; text: "Änderungen seit" }
        RowLayout {
            spacing: 8
            Layout.leftMargin: 24
            enabled: modeSince.checked
            DateField { id: sinceDate }
            TimeField { id: sinceTime; objectName: "sinceTime" }
            Label {
                text: Store.lastExport() !== "" ? "letzter Export: " + Store.lastExport() : ""
                color: palette.placeholderText
                font.pixelSize: 11
            }
        }

        RadioButton { id: modeAthlete; text: "Trainingswochen eines Sportlers" }
        RowLayout {
            spacing: 8
            Layout.leftMargin: 24
            enabled: modeAthlete.checked
            ComboBox {
                id: athleteBox
                implicitWidth: 200
                model: Store.athletes
                textRole: "displayName"
                valueRole: "id"
            }
            Label { text: "von" }
            TextField { id: fromWeek; implicitWidth: 80; horizontalAlignment: TextInput.AlignHCenter }
            Label { text: "bis" }
            TextField { id: toWeek; implicitWidth: 80; horizontalAlignment: TextInput.AlignHCenter }
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 8
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: palette.placeholderText
            text: "Die Datei lässt sich auf einem anderen Rechner über „Daten“ › „Importieren…“ einlesen. Gelöschte Einträge werden dabei ebenfalls entfernt."
        }

        Label {
            Layout.fillWidth: true
            visible: dialog.summary !== ""
            text: dialog.summary
            wrapMode: Text.Wrap
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "Schließen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }
        IconButton {
            iconName: "file-down"
            text: "Exportieren…"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.ApplyRole
            onClicked: {
                saveDialog.selectedFile = Store.suggestedExportUrl()
                saveDialog.open()
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Export speichern"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "bak"
        nameFilters: ["Datensicherung (*.bak)"]
        onAccepted: {
            const mode = modeSince.checked ? "since" : modeAthlete.checked ? "athlete" : "all"
            dialog.summary = Store.exportBak(selectedFile, mode, sinceDate.text, sinceTime.time,
                                            athleteBox.currentValue || "", fromWeek.text, toWeek.text)
        }
    }
}
