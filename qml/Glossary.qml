pragma Singleton
import QtQuick
import Trainingsplaner

// The terms and abbreviations of the program, for tooltips and the help page
QtObject {
    readonly property var terms: [
        { term: "TÜ", text: "Trainingsübung. Die Nummern und Namen sind die des alten Programms." },
        { term: "TE", text: "Trainingseinheit. Bis zu drei an einem Tag (1. TE, 2. TE, 3. TE)." },
        { term: "Plan / Ist", text: "Plan ist die geplante Woche, Ist das tatsächlich absolvierte Training." },
        { term: "Laststufe", text: "Ein Gewicht mit Wiederholungen und Sätzen, z. B. 80 kg 3/2." },
        { term: "SG/ANZ", text: "Wiederholungen je Satz / Anzahl der Sätze einer Laststufe: 3/2 sind 2 Sätze zu je 3 Wiederholungen." },
        { term: "UG", text: "Ungültige (fehlgeschlagene) Versuche einer Laststufe, nur im Ist." },
        { term: "WH", text: "Wiederholungen: Summe aller Wiederholungen (Wiederholungen je Satz × Sätze)." },
        { term: "Tonnage", text: "Bewegte Last: Summe aus Gewicht × Wiederholungen, in Tonnen (t)." },
        { term: "MHG", text: "Mittleres Hantelgewicht: Tonnage geteilt durch WH, in kg." },
        { term: "BW", text: "Bestwert: das höchste Gewicht einer Übung in der Woche bzw. Einheit." },
        { term: "K1–K7", text: "Die sieben Übungsgruppen der Wochenauswertung. K1–5 fasst die Gruppen 1 bis 5 zusammen." },
        { term: "AMKT", text: "Allgemeine Übungen (Gruppen 8 und 9), meist als Text erfasst, z. B. „3x8“." },
        { term: "MAZ", text: "Makrozyklus: ein mehrwöchiger Trainingsabschnitt, z. B. die Vorbereitung auf einen Wettkampf." },
        { term: "RO", text: "Rahmenorientierung: der Rahmenplan einer MAZ, in Prozent." },
        { term: "ITP", text: "Individueller Trainingsplan eines Sportlers, aus der RO berechnet oder frei geplant." },
        { term: "Zweikampf", text: "Bester gültiger Versuch im Reißen plus bester gültiger Versuch im Stoßen." }
    ]

    function explain(term) {
        const t = terms.find(x => x.term === term)
        return t ? t.term + ": " + t.text : ""
    }

    // "K2" → "K2: 6 Reißen erhöhte Position, 7 Standreißen, …"
    function group(number) {
        const names = Store.catalog.filter(e => e.group === number).map(e => e.id + " " + e.name)
        return "K" + number + ": " + names.join(", ")
    }
}
