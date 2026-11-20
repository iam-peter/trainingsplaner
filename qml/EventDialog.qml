import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// A calendar entry beside the competitions: a Lehrgang over some days or
// a Diagnostik/Test on one day, for one athlete.
AppDialog {
    id: dialog
    objectName: "eventDialog"

    property string eventId: ""
    property string error: ""
    readonly property bool lehrgang: kindBox.currentIndex === 0

    // A new one on a day ("yyyy-MM-dd"), or the one with this id
    function show(id, date, athleteId) {
        const e = id ? Store.event(id) : null
        eventId = e && e.id ? e.id : ""
        error = ""
        athleteBox.value = e ? e.athleteId : athleteId
        kindBox.currentIndex = e ? e.kind - 1 : 0
        fromField.text = e ? e.from : Store.formatDate(date || Store.today())
        toField.text = e ? e.to : ""
        titleField.text = e ? e.title : ""
        placeField.text = e ? e.place : ""
        noteField.text = e ? e.note : ""
        open()
        titleField.forceActiveFocus()
    }

    function save() {
        error = Store.saveEvent({ id: eventId, athleteId: athleteBox.value || "", kind: kindBox.currentIndex + 1,
                                  from: fromField.text, to: lehrgang ? toField.text : "", title: titleField.text,
                                  place: placeField.text, note: noteField.text })
        if (error === "")
            close()
    }

    title: eventId !== "" ? "Termin ändern" : "Termin eintragen"
    standardButtons: Dialog.NoButton

    contentItem: GridLayout {
        columns: 2
        columnSpacing: 12
        rowSpacing: 8
        Label { text: "Sportler:" }
        ValueComboBox {
            id: athleteBox
            objectName: "eventAthlete"
            implicitWidth: 260
            model: Store.selectableAthletes
            displayText: currentIndex < 0 ? "Sportler wählen" : currentText
            onChosen: (v) => value = v
        }
        Label { text: "Art:" }
        ComboBox {
            id: kindBox
            objectName: "eventKind"
            implicitWidth: 260
            model: Store.eventKinds
        }
        Label { text: dialog.lehrgang ? "Von:" : "Datum:" }
        RowLayout {
            spacing: 8
            DateField { id: fromField; objectName: "eventFrom" }
            Label { visible: dialog.lehrgang; text: "bis" }
            DateField { id: toField; objectName: "eventTo"; visible: dialog.lehrgang }
        }
        Label { text: "Bezeichnung:" }
        TextField {
            id: titleField
            objectName: "eventTitle"
            Layout.preferredWidth: 300
            placeholderText: dialog.lehrgang ? "z.B. Kaderlehrgang" : "z.B. Komplexe Leistungsdiagnostik"
            onAccepted: dialog.save()
        }
        Label { text: "Ort:" }
        TextField {
            id: placeField
            objectName: "eventPlace"
            Layout.preferredWidth: 300
            onAccepted: dialog.save()
        }
        Label { text: "Bemerkung:" }
        TextField {
            id: noteField
            objectName: "eventNote"
            Layout.preferredWidth: 300
            onAccepted: dialog.save()
        }
        Label {
            Layout.columnSpan: 2
            visible: dialog.error !== ""
            text: dialog.error
            color: Styles.TokenInterface.semantics.danger_default
        }
    }

    footer: DialogButtons {
        leading: IconButton {
            objectName: "removeEvent"
            visible: dialog.eventId !== ""
            iconName: "trash-2"
            text: "Löschen"
            DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
            onClicked: {
                Store.removeEvent(dialog.eventId)
                dialog.close()
            }
        }
        Button {
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }
        IconButton {
            objectName: "saveEvent"
            iconName: "save"
            text: "Speichern"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }
}
