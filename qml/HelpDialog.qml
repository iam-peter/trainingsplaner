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
        ["Enter", "Trainingseinheit neben der Woche bearbeiten"],
        ["Entf", "Trainingseinheit löschen (mit Rückfrage)"],
        ["Strg+C / Strg+V", "Trainingseinheit kopieren / einfügen"],
        ["Menütaste, Rechtsklick", "Weitere Befehle zur Trainingseinheit"],
        ["Strg+Z / Strg+Y", "Rückgängig / Wiederholen"],
        ["Strg+S", "Trainingseinheit speichern (sonst beim Wechsel)"],
        ["Esc", "Trainingseinheit oder Dialog schließen"],
        ["↑ / ↓ in einem Feld", "Gewicht, Wiederholungen, Sätze, UG weiterzählen"],
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
                          + "<b>Wochenplan:</b> Sportler und Woche wählen. Ein Klick in eine Trainingseinheit öffnet sie "
                          + "neben der Woche; Änderungen werden beim Wechsel zu einer anderen Einheit oder beim Schließen "
                          + "gespeichert und lassen sich rückgängig machen. Mit dem Pfeil-Symbol kommt sie in ein eigenes "
                          + "Fenster. Ein Klick auf eine Übung öffnet „Erfassung TÜ“ im selben Bereich: "
                          + "diese Übung in allen Einheiten der Woche, in der Woche hervorgehoben. Plan und Ist umschalten "
                          + "oben, „Vorwoche“ zeigt die Woche davor darüber; wie viele Einheiten pro Tag die Woche zeigt, "
                          + "steht unter Einstellungen › Trainingszeiten. „Monat“ zeigt den Monat mit Belastung, "
                          + "Einheiten und Wettkämpfen; ein Doppelklick auf einen Tag trägt einen Wettkampf ein, "
                          + "„Alle Sportler“ zeigt die Wettkämpfe aller. „Woche kopieren“ und „Einfügen“ übertragen ganze Wochen, auch zu anderen Sportlern.<br><br>"
                          + "<b>Planung:</b> MAZ anlegen; über „Rahmenorientierung“ beim MAZ die Rahmenorientierung (RO) "
                          + "in Prozent eintragen (zurück mit „‹ MAZ“). Unter „ITP“ daraus mit „Vorlage“ den "
                          + "individuellen Trainingsplan des Sportlers berechnen.<br><br>"
                          + "<b>Analyse:</b> Abschnittsanalyse über beliebige Wochen oder eine MAZ, Grafik je Übung, "
                          + "Belastungstabellen. Die Tabellen stehen sofort da und folgen den Einstellungen. „Kopieren“ "
                          + "legt sie für eine Tabellenkalkulation in die Zwischenablage, „Speichern unter“ schreibt ein PDF "
                          + "oder eine CSV-Datei. Grafiken zeigen beim Darüberfahren die Werte und lassen sich als Bild speichern.<br><br>"
                          + "<b>Wettkämpfe:</b> Versuche eintragen, einen Fehlversuch mit der Leertaste oder einem Rechtsklick im Feld als ungültig markieren (rot, durchgestrichen), und die Entwicklung als Grafik ansehen.<br><br>"
                          + "<b>Datensicherung:</b> Daten › Exportieren schreibt eine Datei im Format des alten Programms."
                }
            }
        }
    }
}
