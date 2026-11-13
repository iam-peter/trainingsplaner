import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Shown on the first start with an empty database
AppDialog {
    id: dialog

    signal importRequested()
    signal demoCreated(string athleteId)

    title: "Willkommen"
    closePolicy: Popup.NoAutoClose
    width: 560

    function finish() {
        Store.trainer = trainerField.text.trim()
        Store.finishFirstStart()
        close()
    }

    contentItem: DialogScroll {
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 12

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Der Trainingsplaner für Gewichtheben: Wochenpläne, Planung, Auswertungen und Wettkämpfe."
            }

            Label { text: "Name des Trainers (erscheint auf den Ausdrucken):" }
            TextField {
                id: trainerField
                objectName: "trainerField"
                Layout.fillWidth: true
                text: Store.trainer
                placeholderText: "z. B. Max Mustermann"
            }

            Label {
                Layout.topMargin: 8
                text: "Womit möchten Sie beginnen?"
                font.bold: true
            }

            IconButton {
                Layout.fillWidth: true
                iconName: "import"
                text: "Daten aus dem alten Programm importieren"
                onClicked: {
                    dialog.finish()
                    dialog.importRequested()
                }
            }
            IconButton {
                objectName: "demoButton"
                Layout.fillWidth: true
                iconName: "users"
                text: "Mit Beispieldaten ausprobieren"
                onClicked: {
                    dialog.finish()
                    dialog.demoCreated(Store.createDemoData())
                }
            }
            IconButton {
                Layout.fillWidth: true
                iconName: "user-plus"
                text: "Leer beginnen und Sportler anlegen"
                onClicked: dialog.finish()
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 11
                color: Styles.TokenInterface.semantics.text_muted
                text: "Beispieldaten sind frei erfunden und lassen sich über das Hantel-Menü oben links › Beispieldaten entfernen wieder löschen. "
                      + "F1 öffnet jederzeit die Hilfe."
            }
        }
    }
}
