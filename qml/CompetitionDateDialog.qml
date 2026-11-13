import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// A competition date entered from the month view: who, when, what, where.
// The results are entered later on the Wettkämpfe page; changing the date
// here keeps them.
AppDialog {
    id: dialog

    // The competition changed, null for a new one
    property var competition: null
    property string error: ""

    // A new one on a day (date "yyyy-MM-dd"), or one to change
    function show(c, date, athleteId) {
        competition = c
        error = ""
        athleteBox.value = c ? c.athleteId : athleteId
        dateField.text = Store.formatDate(c ? c.date : (date || Store.today()))
        typeBox.currentIndex = c ? c.type : 0
        nameField.text = c ? c.name : ""
        placeField.text = c ? c.place : ""
        open()
        nameField.forceActiveFocus()
    }

    function save() {
        const c = competition
        error = Store.saveCompetitionDate(athleteBox.value, dateField.text, typeBox.currentIndex,
                                          nameField.text, placeField.text, c ? c.date : "", c ? c.time : "")
        if (error === "")
            close()
    }

    title: competition ? "Wettkampf ändern" : "Wettkampf eintragen"
    standardButtons: Dialog.NoButton

    contentItem: GridLayout {
        columns: 2
        columnSpacing: 12
        rowSpacing: 8
        Label { text: "Sportler:" }
        ValueComboBox {
            id: athleteBox
            objectName: "athleteBox"
            implicitWidth: 260
            // A competition stays with its athlete
            enabled: dialog.competition === null
            model: Store.selectableAthletes
            displayText: currentIndex < 0 ? "Sportler wählen" : currentText
            onChosen: (v) => value = v
        }
        Label { text: "Datum:" }
        DateField { id: dateField; objectName: "dateField" }
        Label { text: "Art:" }
        ComboBox {
            id: typeBox
            implicitWidth: 260
            model: Store.competitionTypes
        }
        Label { text: "Wettkampf:" }
        TextField {
            id: nameField
            objectName: "nameField"
            Layout.preferredWidth: 300
            placeholderText: "z.B. LM Jugend"
            // Enter takes a suggestion while the list is open
            onAccepted: if (!suggestions.visible) dialog.save()
            Keys.onPressed: (event) => suggestions.handleKey(event)
            // The DGJ's youth competitions, with the type they are
            SuggestionPopup {
                id: suggestions
                field: nameField
                width: 460
                suggestions: Store.youthCompetitions
                onChosen: (item) => {
                    nameField.text = item.text
                    typeBox.currentIndex = item.type
                }
            }
        }
        Label { text: "Ort:" }
        TextField {
            id: placeField
            Layout.preferredWidth: 300
            onAccepted: dialog.save()
        }
        Label {
            Layout.columnSpan: 2
            visible: dialog.error !== ""
            text: dialog.error
            color: Styles.TokenInterface.semantics.danger_default
        }
        // Youth athletes: one competition a week; the DM norm for a DM
        Label {
            objectName: "weekWarning"
            Layout.columnSpan: 2
            Layout.preferredWidth: 400
            wrapMode: Text.Wrap
            visible: text !== ""
            text: dialog.opened ? (Store.dataVersion, Store.weekConflict(athleteBox.value || "", dateField.text,
                                                                         dialog.competition ? dialog.competition.date : "",
                                                                         dialog.competition ? dialog.competition.time : ""))
                                : ""
            color: "#c2410c"
        }
        Label {
            objectName: "normNote"
            Layout.columnSpan: 2
            Layout.preferredWidth: 400
            wrapMode: Text.Wrap
            visible: text !== ""
            text: dialog.opened && (typeBox.currentIndex === 1 || nameField.text.indexOf("DM") >= 0)
                  ? (Store.dataVersion, Store.youthStatus(athleteBox.value || "", dateField.text).dm?.text ?? "") : ""
        }
        Label {
            Layout.columnSpan: 2
            Layout.preferredWidth: 400
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: Styles.TokenInterface.semantics.text_muted
            text: dialog.competition && dialog.competition.hasResult
                  ? "Die Ergebnisse dieses Wettkampfs bleiben erhalten."
                  : "Die Ergebnisse kommen nach dem Wettkampf unter „Wettkämpfe“ dazu."
        }
    }

    footer: DialogButtons {
        leading: IconButton {
            objectName: "removeButton"
            visible: dialog.competition !== null && !dialog.competition.hasResult
            iconName: "trash-2"
            text: "Löschen"
            onClicked: {
                Store.removeCompetition(dialog.competition.athleteId, dialog.competition.date, dialog.competition.time)
                dialog.close()
            }
        }
        Button {
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }
        IconButton {
            objectName: "saveButton"
            iconName: "save"
            text: "Speichern"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.save()
        }
    }
}
