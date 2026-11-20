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
                    text: "<b>Daten aus dem alten Programm:</b> Hantel-Menü oben links › Importieren liest die Datensicherung "
                          + "(winwotaxp.bak) ein. Neuere Einträge im Programm bleiben dabei erhalten.<br><br>"
                          + "<b>Projekte:</b> alle Daten stehen in einer Projektdatei; jede Änderung wird sofort darin "
                          + "gespeichert. Im Hantel-Menü oben links legt „Neues Projekt…“ eine leere an, „Öffnen…“ und „Zuletzt geöffnet“ "
                          + "wechseln zu einer anderen, „Speichern unter…“ legt eine Kopie an und arbeitet darin weiter. "
                          + "Beim Start öffnet das Programm das zuletzt benutzte Projekt.<br><br>"
                          + "<b>Sportler:</b> unter „Sportler“ anlegen und bearbeiten; Kader, Verein usw. mit Zeiträumen (Stift-Symbol daneben).<br><br>"
                          + "<b>Wochenplan:</b> Sportler und Woche wählen. Ein Klick in eine Trainingseinheit öffnet sie "
                          + "neben der Woche; Änderungen werden beim Wechsel zu einer anderen Einheit oder beim Schließen "
                          + "gespeichert und lassen sich rückgängig machen. Mit dem Pfeil-Symbol kommt sie in ein eigenes "
                          + "Fenster. Ein Klick auf eine Übung öffnet „Erfassung TÜ“ im selben Bereich: "
                          + "diese Übung in allen Einheiten der Woche, in der Woche hervorgehoben. Plan und Ist umschalten "
                          + "oben, „Vorwoche“ zeigt die Woche davor darüber; wie viele Einheiten pro Tag die Woche zeigt, "
                          + "steht unter Einstellungen › Trainingszeiten. Unter der Woche setzen h, m und g ihre Belastung "
                          + "(hoch, mittel, gesenkt), dieselbe wie im ITP unter „Bel.“. „Monat“ zeigt den Monat mit Belastung, "
                          + "Einheiten und Wettkämpfen; ein Doppelklick auf einen Tag trägt einen Wettkampf ein, "
                          + "„Alle Sportler“ zeigt die Wettkämpfe aller. „Verlauf“ zeigt den Belastungsverlauf: Gewicht einer "
                          + "Übung und Wiederholungen über die Wochen des MAZ, gegen das ITP, mit Ideallinie.<br><br>"
                          + "<b>Jugend:</b> beim Eintragen eines Wettkampfs schlägt das Programm die Wettkämpfe der DGJ vor; "
                          + "für Sportler bis AK 17 warnt es bei einem zweiten Wettkampf in derselben Woche. Für AK 14–17 "
                          + "steht die Norm der DM Nachwuchs unter „Wettkämpfe“ und bei den Terminen (AK 16–17 je "
                          + "Gewichtsklasse, AK 14 und 15 je Kilogramm Körpergewicht); die Normen lassen sich "
                          + "unter Einstellungen › Normen ändern. „Woche kopieren“ und „Einfügen“ übertragen ganze Wochen, auch zu anderen Sportlern.<br><br>"
                          + "<b>Planung:</b> MAZ anlegen, auf Wunsch aus einer Vorlage der Rahmentrainingskonzeption (U13, U15, "
                          + "U17, U20), die Wochen, Phasen und Rahmenorientierung mitbringt; über „Rahmenorientierung“ beim MAZ die Rahmenorientierung (RO) "
                          + "in Prozent eintragen (zurück mit „‹ MAZ“). Unter „ITP“ daraus mit „Vorlage“ den "
                          + "individuellen Trainingsplan des Sportlers berechnen. Rot sind Werte über dem "
                          + "Trainingsmittelkatalog 2018 für das Alter (BW %, Übungen und Komplexe ab welcher AK); die "
                          + "Maus über der Zahl nennt den Grund. „Skalieren“ ändert gewählte Wochen und Werte um einen Faktor, "
                          + "z. B. 90 % nach einer Krankheit. Den Richtwert des TMK für die WH je Woche nennen die Spalten "
                          + "K1–K6 und K1-7 und zeigt der Belastungsverlauf als violette Linie.<br><br>"
                          + "<b>Analyse:</b> Abschnittsanalyse über beliebige Wochen oder eine MAZ, Grafik je Übung, "
                          + "Belastungstabellen. Die Tabellen stehen sofort da und folgen den Einstellungen. „Kopieren“ "
                          + "legt sie für eine Tabellenkalkulation in die Zwischenablage, „Speichern unter“ schreibt ein PDF "
                          + "oder eine CSV-Datei. Grafiken zeigen beim Darüberfahren die Werte und lassen sich als Bild speichern.<br><br>"
                          + "<b>Wettkämpfe:</b> Versuche eintragen, einen Fehlversuch mit der Leertaste oder einem Rechtsklick im Feld als ungültig markieren (rot, durchgestrichen), und die Entwicklung als Grafik ansehen.<br><br>"
                          + "<b>Datensicherung:</b> Hantel-Menü › Exportieren schreibt eine Datei im Format des alten Programms."
                }
            }
        }
    }
}
