import QtQuick
import Trainingsplaner

// Keeps the two fields of a range in order, "von" not after "bis". When
// an edit puts one past the other, the other follows and keeps the span
// the two had before the edit, as a calendar moves an appointment's end
// with its start. An empty or unreadable field is left alone.
//
// kind: "time" (TimeField), "week" (WeekField) or "date" (DateField)
QtObject {
    id: link

    required property Item from
    required property Item to
    property string kind: "time"

    // The span before the current edit, in minutes or days; -1 unknown
    property real span: -1

    // Minutes of the day, or days since 1970; NaN when there is none
    function value(field) {
        if (kind === "time") {
            const t = field.normalized(field.text)
            return t === "" ? NaN : parseInt(t.slice(0, 2)) * 60 + parseInt(t.slice(3))
        }
        const iso = kind === "week" ? field.monday : Store.parseDate(field.text)
        if (iso === "")
            return NaN
        return Math.round(Date.UTC(parseInt(iso.slice(0, 4)), parseInt(iso.slice(5, 7)) - 1,
                                   parseInt(iso.slice(8, 10))) / 86400000)
    }

    function setValue(field, v) {
        let text
        if (kind === "time") {
            v = Math.max(0, Math.min(23 * 60 + 59, v))
            const h = Math.floor(v / 60)
            const m = v % 60
            text = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
        } else {
            const iso = new Date(v * 86400000).toISOString().slice(0, 10)
            text = kind === "week" ? Store.weekLabel(iso) : Store.formatDate(iso)
        }
        if (text !== field.text) {
            field.text = text
            // Counts as an edit, so the form knows it changed
            field.textEdited()
        }
    }

    // The span of the two while they are in order; out of order, or with
    // one empty, the last one stays
    function remember() {
        const a = value(from)
        const b = value(to)
        if (!isNaN(a) && !isNaN(b) && b >= a)
            span = b - a
    }

    function follow(edited) {
        const a = value(from)
        const b = value(to)
        if (!isNaN(a) && !isNaN(b) && b < a) {
            const keep = Math.max(0, span)
            if (edited === from)
                setValue(to, a + keep)
            else
                setValue(from, b - keep)
        }
        remember()
    }

    // Texts set from outside (a record loaded) give the span too; what
    // is typed counts only once the edit is done
    property Connections fromEdits: Connections {
        target: link.from
        function onEditStarted() { link.remember() }
        function onEditDone() { link.follow(link.from) }
        function onTextChanged() { if (!link.from.activeFocus) link.remember() }
    }
    property Connections toEdits: Connections {
        target: link.to
        function onEditStarted() { link.remember() }
        function onEditDone() { link.follow(link.to) }
        function onTextChanged() { if (!link.to.activeFocus) link.remember() }
    }
}
