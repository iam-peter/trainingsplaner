import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// F1: terms, keyboard and first steps
AppDialog {
    id: dialog

    title: "Hilfe"
    standardButtons: Dialog.Close
    width: parent ? Math.min(parent.width - 40, 760) : 760
    height: parent ? Math.min(parent.height - 40, 620) : 620

    readonly property var keys: [
        ["Strg+← / Strg+→", "Vorige / nächste Woche"],
        ["Pfeiltasten", "Zwischen den Trainingseinheiten wechseln"],
        ["Enter", "Trainingseinheit bearbeiten"],
        ["Entf", "Trainingseinheit löschen (mit Rückfrage)"],
        ["Strg+C / Strg+V", "Trainingseinheit kopieren / einfügen"],
        ["Menütaste, Rechtsklick", "Weitere Befehle zur Trainingseinheit"],
        ["Strg+Z / Strg+Y", "Rückgängig / Wiederholen"],
        ["Strg+S", "Speichern"],
        ["Esc", "Dialog schließen"],
        ["Strg+P", "Wochenplan drucken"],
        ["Strg+1 … Strg+5", "Sportler, Wochenplan, Planung, Analyse, Wettkämpfe"],
        ["F1", "Diese Hilfe"]
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        AppTabBar {
            id: tabs
            Layout.fillWidth: true
            AppTabButton { text: "Begriffe" }
            AppTabButton { text: "Tastatur" }
            AppTabButton { text: "Erste Schritte" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            ScrollView {
                // No overshoot at the ends
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                clip: true
                contentWidth: availableWidth
                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 8
                    Repeater {
                        model: Glossary.terms
                        delegate: Label {
                            required property var modelData
                            required property int index
                            Layout.row: index
                            Layout.column: 0
                            Layout.alignment: Qt.AlignTop
                            text: modelData.term
                            font.bold: true
                        }
                    }
                    Repeater {
                        model: Glossary.terms
                        delegate: Label {
                            required property var modelData
                            required property int index
                            Layout.row: index
                            Layout.column: 1
                            Layout.fillWidth: true
                            text: modelData.text
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            ScrollView {
                // No overshoot at the ends
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                clip: true
                contentWidth: availableWidth
                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 8
                    Repeater {
                        model: dialog.keys
                        delegate: Label {
                            required property var modelData
                            required property int index
                            Layout.row: index
                            Layout.column: 0
                            text: modelData[0]
                            font.family: "JetBrains Mono"
                        }
                    }
                    Repeater {
                        model: dialog.keys
                        delegate: Label {
                            required property var modelData
                            required property int index
                            Layout.row: index
                            Layout.column: 1
                            Layout.fillWidth: true
                            text: modelData[1]
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            ScrollView {
                // No overshoot at the ends
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                clip: true
                contentWidth: availableWidth
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.StyledText
                    lineHeight: 1.2
                    text: "<b>Daten aus dem alten Programm:</b> Daten › Importieren liest die Datensicherung "
                          + "(winwotaxp.bak) ein. Neuere Einträge im Programm bleiben dabei erhalten.<br><br>"
                          + "<b>Sportler:</b> unter „Sportler“ anlegen und bearbeiten; Kader, Verein usw. mit Zeiträumen (Stift-Symbol daneben).<br><br>"
                          + "<b>Wochenplan:</b> Sportler und Woche wählen. Ein Klick in eine Trainingseinheit öffnet sie, "
                          + "ein Klick auf eine Übung bearbeitet diese Übung für die ganze Woche. Plan und Ist umschalten "
                          + "oben. „Woche kopieren“ und „Einfügen“ übertragen ganze Wochen, auch zu anderen Sportlern.<br><br>"
                          + "<b>Planung:</b> MAZ anlegen, Rahmenorientierung (RO) in Prozent eintragen und daraus den "
                          + "individuellen Trainingsplan (ITP) berechnen.<br><br>"
                          + "<b>Analyse:</b> Abschnittsanalyse über beliebige Wochen oder eine MAZ, Grafik je Übung, "
                          + "Belastungstabellen. Grafiken zeigen beim Darüberfahren die Werte und lassen sich als Bild speichern.<br><br>"
                          + "<b>Wettkämpfe:</b> Versuche eintragen, einen Fehlversuch mit der Leertaste oder einem Rechtsklick im Feld als ungültig markieren (rot, durchgestrichen), und die Entwicklung als Grafik ansehen.<br><br>"
                          + "<b>Datensicherung:</b> Daten › Exportieren schreibt eine Datei im Format des alten Programms."
                }
            }
        }
    }
}
