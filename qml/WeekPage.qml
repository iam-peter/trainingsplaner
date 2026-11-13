import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Trainingsplaner

Page {
    id: page

    property string athleteId
    property string monday: Store.mondayOf(Store.today())
    property string variant: "P"
    property var weekData: ({})
    // The same week in the other variant (Ist while Plan is shown, and the
    // reverse): its days and sessions count too, so a planned session keeps
    // its place while its Ist is entered
    property var otherWeek: ({})
    // A row asked for with "Weitere Einheit", until the week changes
    property int extraRows: 0

    // The month instead of the week, and which month ("yyyy-MM-dd", any
    // day in it); the choice of view is kept
    readonly property bool monthMode: viewSettings.monthMode
    property string monthDay: Store.today()
    function showMonth(on) {
        if (on === monthMode)
            return
        if (on) {
            if (!closePanel())
                return
            // The month the week mostly lies in (its Thursday)
            const d = new Date(monday + "T12:00:00")
            d.setDate(d.getDate() + 3)
            monthDay = isoDate(d)
        }
        viewSettings.monthMode = on
    }
    function shiftMonth(delta) {
        const d = new Date(monthDay + "T12:00:00")
        d.setDate(1)
        d.setMonth(d.getMonth() + delta)
        monthDay = isoDate(d)
    }
    function isoDate(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
    }
    // Last week, the ITP's targets, the MAZ and the next competition
    // (Store.weekContext)
    property var context: ({})

    // "Vorwoche": the week before, above the week, read only; its Ist where
    // it has one, else its Plan
    readonly property bool showPrevious: Store.showPreviousWeek
    readonly property string previousMonday: Store.addWeeks(monday, -1)
    readonly property string previousVariant: context.previous ? context.previous.variant : "I"
    property var previousData: ({})
    readonly property var previousNumbers: {
        const days = [[], [], [], [], [], [], []]
        for (const s of (previousData.sessions || [])) {
            if (days[s.day - 1].indexOf(s.number) < 0)
                days[s.day - 1].push(s.number)
        }
        for (const d of days)
            d.sort()
        return days
    }
    readonly property int previousRows: {
        if (!showPrevious)
            return 0
        let n = compact ? 1 : Store.sessionsPerDay
        for (const d of previousNumbers)
            n = Math.max(n, compact ? d.length : (d.length > 0 ? d[d.length - 1] : 0))
        return Math.min(3, n)
    }
    function previousNumberAt(day, row) {
        return compact ? (previousNumbers[day - 1][row - 1] || 0) : row
    }
    function previousSessionAt(day, number) {
        for (const s of (previousData.sessions || [])) {
            if (s.day === day && s.number === number)
                return s
        }
        return null
    }
    // Shows the week before as it was shown above
    function openPrevious() {
        const v = previousVariant
        monday = previousMonday
        variant = v
    }
    // 1-7 when today is in the week before (planning next week), else 0
    readonly property int previousTodayDay: {
        const t = Store.today()
        return Store.mondayOf(t) === previousMonday ? (new Date(t + "T12:00:00").getDay() + 6) % 7 + 1 : 0
    }

    // The week's place in the cycle, for the line above the days
    readonly property string cycleText: {
        const parts = []
        const z = context.maz
        if (z && z.has)
            parts.push(z.name + (z.phase ? " · " + z.phase : "") + " · Woche " + z.week + " von " + z.weeks)
        if (context.load > 0)
            parts.push("Belastung " + context.loadText)
        if (context.position)
            parts.push("WK-Lage " + context.position)
        return parts.join("   ·   ")
    }
    readonly property string nextCompetitionText: {
        const n = context.next
        if (!n || !n.has)
            return ""
        return "Nächster Wettkampf: " + n.name + ", " + n.date
               + (n.days === 0 ? " (heute)" : n.days === 1 ? " (morgen)" : " (in " + n.days + " Tagen)")
    }
    // "Vorwoche 45/2026 (Ist): 241Wh / 63kg   ·   ITP: 230Wh / 66kg   ·   Woche gegen ITP: −7 % WH"
    readonly property var comparison: {
        const parts = []
        const p = context.previous
        if (p && p.has)
            parts.push("Vorwoche " + p.label + " (" + (p.variant === "I" ? "Ist" : "Plan") + "): "
                       + p.k17.wh + "Wh / " + p.k17.mhg + "kg")
        const t = context.target
        let deviation = 0
        if (t && t.has && t.k17.wh > 0) {
            parts.push("ITP: " + t.k17.wh + "Wh" + (t.k17.mhg > 0 ? " / " + t.k17.mhg + "kg" : ""))
            const cur = weekData.k17Stats ? weekData.k17Stats.wh : 0
            if (cur > 0) {
                deviation = Math.round((cur - t.k17.wh) * 100 / t.k17.wh)
                parts.push("Woche gegen ITP: " + (deviation > 0 ? "+" : deviation < 0 ? "−" : "±")
                           + Math.abs(deviation) + " % WH")
            }
        }
        return { text: parts.join("   ·   "), deviation: deviation }
    }
    // A group's figures beside its own: "VW 36 · ITP 32"
    function groupComparison(index) {
        const parts = []
        const p = context.previous
        if (p && p.has && p.groups[index] && p.groups[index].wh > 0)
            parts.push("VW " + p.groups[index].wh)
        const t = context.target
        if (t && t.has && t.groups[index] > 0)
            parts.push("ITP " + t.groups[index])
        return parts.join(" · ")
    }

    // The session numbers of each day in either variant, sorted
    readonly property var dayNumbers: {
        const days = [[], [], [], [], [], [], []]
        for (const w of [weekData, otherWeek]) {
            for (const s of (w.sessions || [])) {
                if (days[s.day - 1].indexOf(s.number) < 0)
                    days[s.day - 1].push(s.number)
            }
        }
        for (const d of days)
            d.sort()
        return days
    }
    // One session a day (Einheiten pro Tag 1): each day lists its own
    // sessions from the top, whatever their number, as a single session
    // is often a 2. TE (the afternoon) in WinWoTA's data. With 2 or 3 the
    // rows are the session numbers, as in WinWoTA.
    readonly property bool compact: Store.sessionsPerDay === 1
    // The number a session on an empty day gets: the one the week (else
    // the week before) uses most, else 1
    property int usualNumber: 1
    // Rows of sessions: as many as set, and as many as the week uses, so
    // nothing is hidden
    readonly property int rows: {
        let n = Math.max(Store.sessionsPerDay, extraRows)
        for (const d of dayNumbers)
            n = Math.max(n, compact ? d.length : (d.length > 0 ? d[d.length - 1] : 0))
        return Math.min(3, n)
    }
    // The session number shown in a day's row
    function numberAt(day, row) {
        if (!compact)
            return row
        const used = dayNumbers[day - 1]
        if (row <= used.length)
            return used[row - 1]
        // Below the day's sessions: the next numbers after them
        const start = used.length > 0 ? used[used.length - 1] + 1 : usualNumber
        const free = [1, 2, 3].filter(n => used.indexOf(n) < 0)
        const ordered = free.filter(n => n >= start).concat(free.filter(n => n < start))
        return ordered[row - used.length - 1] || 0
    }
    // Days with a session in either variant, or in the week before when
    // that is shown, so the two weeks keep the same columns
    readonly property var usedDays: dayNumbers.map((d, i) => d.length > 0 || (showPrevious && previousNumbers[i].length > 0))
    // A day without sessions is a narrow column, once another day has some
    function narrowDay(day) {
        return usedDays.indexOf(true) >= 0 && !usedDays[day - 1]
    }
    readonly property int narrowWidth: 56
    readonly property int wideMinimum: 130

    // The week the note field belongs to, so it is saved to the right week
    // even after the selection has changed.
    property var noteOwner: null

    readonly property bool hasAthlete: athleteId !== ""

    // Picks the first athlete while none is chosen; off in the window,
    // which chooses for all pages
    property bool choosesAthlete: true
    function selectDefaultAthlete() {
        if (choosesAthlete && athleteId === "" && Store.athletes.length > 0)
            athleteId = Store.athletes[0].id
    }

    function start(athlete, weekLabel, session) {
        if (athlete !== "")
            athleteId = athlete
        selectDefaultAthlete()
        if (weekLabel !== "") {
            const m = Store.weekFromLabel(weekLabel)
            if (m !== "")
                monday = m
        }
        if (session.startsWith("ex:")) {
            Qt.callLater(openExercise, parseInt(session.slice(3)))
        } else if (session.startsWith("hist:") || session.startsWith("chart:")) {
            const ex = parseInt(session.split(":")[1])
            Qt.callLater(() => historyDialog.show(athleteId, monday, variant, ex, session.startsWith("chart:")))
        } else if (session !== "") {
            const parts = session.split(":")
            Qt.callLater(openSession, parseInt(parts[0]), parseInt(parts[1] || "1"))
        }
    }

    // Only what was typed or ticked here: a reload after a change from
    // elsewhere (an import, undo) must not write the old note back
    property bool noteDirty: false

    function saveNote() {
        if (noteOwner === null || !noteDirty)
            return
        noteDirty = false
        Store.saveWeekNote(noteOwner.athleteId, noteOwner.monday, noteOwner.variant,
                           noteField.text, injuredBox.checked)
    }

    function reload() {
        stale = false
        saveNote()
        if (!hasAthlete) {
            weekData = {}
            otherWeek = {}
            context = {}
            previousData = {}
            noteOwner = null
            return
        }
        weekData = Store.week(athleteId, monday, variant)
        otherWeek = Store.week(athleteId, monday, variant === "P" ? "I" : "P")
        context = Store.weekContext(athleteId, monday)
        // From the week's own values: bindings on them may not have followed
        // the change yet that started this reload
        previousData = Store.showPreviousWeek
                       ? Store.week(athleteId, Store.addWeeks(monday, -1), context.previous ? context.previous.variant : "I")
                       : {}
        let counts = [0, 0, 0, 0]
        for (const w of [weekData, otherWeek])
            for (const s of (w.sessions || []))
                ++counts[s.number]
        if (counts[1] + counts[2] + counts[3] === 0) {
            for (const s of (Store.week(athleteId, Store.addWeeks(monday, -1), variant).sessions || []))
                ++counts[s.number]
        }
        usualNumber = counts[2] > counts[1] && counts[2] >= counts[3] ? 2 : counts[3] > counts[1] ? 3 : 1
        noteField.text = weekData.note
        injuredBox.checked = weekData.injured
        noteDirty = false
        noteOwner = { athleteId: athleteId, monday: monday, variant: variant }
    }

    // "Weitere Einheit": the next session of the day after the ones it has
    function addSession(day) {
        let n = 1
        for (const w of [weekData, otherWeek]) {
            for (const s of (w.sessions || [])) {
                if (s.day === day)
                    n = Math.max(n, s.number + 1)
            }
        }
        if (n > 3)
            return
        extraRows = Math.max(extraRows, compact ? dayNumbers[day - 1].length + 1 : n)
        openSession(day, n)
    }

    function canAddSession(day) {
        for (const w of [weekData, otherWeek]) {
            for (const s of (w.sessions || [])) {
                if (s.day === day && s.number === 3)
                    return false
            }
        }
        return true
    }

    // 1-7 when today is in the shown week, else 0
    readonly property int todayDay: {
        const t = Store.today()
        return Store.mondayOf(t) === monday ? (new Date(t + "T12:00:00").getDay() + 6) % 7 + 1 : 0
    }

    function sessionAt(day, number) {
        if (!weekData.sessions)
            return null
        for (const s of weekData.sessions) {
            if (s.day === day && s.number === number)
                return s
        }
        return null
    }

    // Erfassung TÜ: the exercise across the week, in the panel; the
    // session shown there before is saved and closed first
    function openExercise(exercise) {
        if (!hasAthlete || !sessionEditor.close())
            return
        saveNote()
        if (!exerciseEditor.edit(athleteId, monday, variant, exercise))
            return
        exerciseEditor.forceActiveFocus()
    }

    // The panel's view that is open, or null
    readonly property Item activeEditor: sessionEditor.opened ? sessionEditor : exerciseEditor.opened ? exerciseEditor : null
    // The exercise Erfassung TÜ edits in the week shown, 0 for none
    readonly property int editedExercise: exerciseEditor.opened && exerciseEditor.athleteId === athleteId
                                          && exerciseEditor.monday === monday && exerciseEditor.variant === variant
                                          ? exerciseEditor.exercise : 0

    // The cell of a day's session, by its number
    function focusSession(day, number) {
        day = Math.min(7, Math.max(1, day))
        for (let row = 1; row <= rows; ++row) {
            if (numberAt(day, row) === number) {
                focusRow(day, row)
                return
            }
        }
        // Not found (gone, or never saved): the day's first row; the number
        // is no row in the compact grid
        focusRow(day, compact ? 1 : number)
    }

    // The cell in a day's row, moved to by the arrow keys
    function focusRow(day, row) {
        day = Math.min(7, Math.max(1, day))
        row = Math.min(rows, Math.max(1, row))
        cells.itemAt((row - 1) * 7 + day - 1).forceActiveFocus()
    }

    function askRemoveSession(day, number) {
        if (!hasAthlete || !sessionAt(day, number) || !savePanel())
            return
        removeConfirm.day = day
        removeConfirm.number = number
        removeConfirm.open()
    }

    function copySession(day, number) {
        if (hasAthlete && sessionAt(day, number) && savePanel())
            Store.copySession(athleteId, monday, variant, day, number)
    }

    function pasteSession(day, number) {
        if (hasAthlete && Store.sessionClipboardLabel !== "" && savePanel())
            Store.pasteSession(athleteId, monday, variant, day, number)
    }

    // Shows the week an undo or redo changed
    function show(change) {
        if (!change.athleteId)
            return
        athleteId = change.athleteId
        monday = change.monday
        variant = change.variant
    }

    function printWeek() {
        if (!hasAthlete)
            return
        saveNote()
        Store.printWeek(athleteId, monday, variant)
    }

    // Keyboard shortcuts while the week plan is shown and no dialog is open
    // Not while typing in the session panel, where Ctrl+←/→ move the cursor
    readonly property bool shortcutsActive: visible && DialogStack.open === 0 && !sessionEditor.activeFocus
                                            && !exerciseEditor.activeFocus
    Shortcut {
        sequence: "Ctrl+Left"
        enabled: page.shortcutsActive
        onActivated: page.monthMode ? page.shiftMonth(-1) : page.monday = Store.addWeeks(page.monday, -1)
    }
    Shortcut {
        sequence: "Ctrl+Right"
        enabled: page.shortcutsActive
        onActivated: page.monthMode ? page.shiftMonth(1) : page.monday = Store.addWeeks(page.monday, 1)
    }
    Shortcut {
        sequences: [StandardKey.Print]
        enabled: page.shortcutsActive && page.hasAthlete
        onActivated: page.printWeek()
    }

    function openSession(day, number) {
        if (!hasAthlete || !(day >= 1 && day <= 7) || !(number >= 1 && number <= 3))
            return
        saveNote()
        // What the panel showed before is saved first; when it cannot be (an
        // impossible time), it stays
        if (!exerciseEditor.close() || !sessionEditor.edit(athleteId, monday, variant, day, number))
            return
        sessionEditor.forceActiveFocus()
    }

    // Is this the session in the panel, or the one under the pointer in
    // Erfassung TÜ?
    function isEdited(day, number) {
        if (editedExercise > 0)
            return exerciseEditor.hoveredDay === day && exerciseEditor.hoveredNumber === number
        return sessionEditor.opened && sessionEditor.athleteId === athleteId && sessionEditor.monday === monday
               && sessionEditor.variant === variant && sessionEditor.day === day && sessionEditor.number === number
    }

    function closePanel() {
        return sessionEditor.close() && exerciseEditor.close()
    }

    // Saves what the panel holds, which stays open: before the grid, the
    // menu or undo change the week, which the panel would otherwise write
    // back over later. False when it cannot be saved.
    function savePanel() {
        return sessionEditor.save() && exerciseEditor.save()
    }

    function undo() {
        if (savePanel())
            show(Store.undo())
    }

    function redo() {
        if (savePanel())
            show(Store.redo())
    }

    // Data changed while the page was hidden
    property bool stale: false
    onVisibleChanged: {
        if (visible && stale)
            reload()
    }

    onShowPreviousChanged: reload()
    // Another week, athlete or variant: the panel saves and closes
    onAthleteIdChanged: { closePanel(); extraRows = 0; reload() }
    onMondayChanged: { closePanel(); extraRows = 0; reload() }
    onVariantChanged: { closePanel(); reload() }
    Connections {
        target: Store
        // While another page is shown, only noted: reloaded when shown
        function onDataVersionChanged() {
            if (page.visible)
                page.reload()
            else
                page.stale = true
        }
        function onAthletesChanged() {
            if (page.athleteId !== "" && !Store.athletes.some(a => a.id === page.athleteId)) {
                page.noteOwner = null
                if (page.choosesAthlete)
                    page.athleteId = ""
            }
            page.selectDefaultAthlete()
        }
    }
    Component.onCompleted: {
        selectDefaultAthlete()
        reload()
    }
    Component.onDestruction: saveNote()

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            // The fullest toolbar: tight gaps, the separators group it
            spacing: 4

            ValueComboBox {
                id: athleteBox
                Layout.preferredWidth: 220
                model: Store.selectableAthletes
                value: page.athleteId
                displayText: currentIndex < 0 ? "Sportler wählen" : currentText
                onChosen: (v) => page.athleteId = v
            }

            ToolSeparator {}

            // Woche or Monat, one group
            RowLayout {
                spacing: -Styles.Primitives.stroke.thin
                IconButton {
                    objectName: "weekViewButton"
                    groupPosition: Styles.GroupStyle.Position.First
                    text: "Woche"
                    highlighted: !page.monthMode
                    onClicked: page.showMonth(false)
                }
                IconButton {
                    objectName: "monthViewButton"
                    groupPosition: Styles.GroupStyle.Position.Last
                    text: "Monat"
                    highlighted: page.monthMode
                    onClicked: page.showMonth(true)
                    toolTip: "Der Monat mit Einheiten und Wettkämpfen"
                }
            }

            // The month between its arrows
            RowLayout {
                visible: page.monthMode
                spacing: -Styles.Primitives.stroke.thin
                IconButton {
                    iconName: "chevron-left"
                    groupPosition: Styles.GroupStyle.Position.First
                    onClicked: page.shiftMonth(-1)
                    toolTip: "Voriger Monat (Strg+←)"
                }
                Label {
                    objectName: "monthTitle"
                    text: monthView.monthData.title || ""
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: 140
                }
                IconButton {
                    iconName: "chevron-right"
                    groupPosition: Styles.GroupStyle.Position.Last
                    onClicked: page.shiftMonth(1)
                    toolTip: "Nächster Monat (Strg+→)"
                }
            }

            // The week between its arrows, as one group with shared edges
            RowLayout {
                visible: !page.monthMode
                spacing: -Styles.Primitives.stroke.thin
                IconButton {
                    iconName: "chevron-left"
                    groupPosition: Styles.GroupStyle.Position.First
                    onClicked: page.monday = Store.addWeeks(page.monday, -1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Vorige Woche (Strg+←)"
                }
                // Typed (then Enter) or picked from its calendar, like a date
                WeekField {
                    id: weekField
                    objectName: "weekField"
                    groupPosition: Styles.GroupStyle.Position.Middle
                    text: Store.weekLabel(page.monday)
                    font.bold: true
                    function show(m) {
                        if (m !== "")
                            page.monday = m
                        text = Qt.binding(() => Store.weekLabel(page.monday))
                    }
                    onAccepted: {
                        show(monday)
                        focus = false
                    }
                    onWeekPicked: (m) => show(m)
                    ToolTip.visible: activeFocus
                    ToolTip.text: "Woche/Jahr eingeben, z.B. 46/2026, dann Enter"
                }
                IconButton {
                    iconName: "chevron-right"
                    groupPosition: Styles.GroupStyle.Position.Last
                    onClicked: page.monday = Store.addWeeks(page.monday, 1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Nächste Woche (Strg+→)"
                }
            }
            IconButton {
                iconName: "calendar"
                text: "Heute"
                onClicked: page.monthMode ? page.monthDay = Store.today() : page.monday = Store.mondayOf(Store.today())
            }
            Label {
                visible: !page.monthMode
                text: Store.weekRange(page.monday)
                color: Styles.TokenInterface.semantics.text_muted
            }

            ToolSeparator {}

            CheckBox {
                id: allBox
                objectName: "allAthletesBox"
                visible: page.monthMode
                text: "Alle Sportler"
                ToolTip.visible: hovered
                ToolTip.text: "Die Wettkämpfe aller Sportler zeigen, wie ein Wandkalender"
            }
            IconButton {
                objectName: "addCompetition"
                visible: page.monthMode
                iconName: "plus"
                text: "Wettkampf"
                onClicked: competitionDialog.show(null, "", page.athleteId)
            }

            RadioButton {
                id: planRadio
                visible: !page.monthMode
                objectName: "planRadio"
                text: "Plan"
                checked: page.variant === "P"
                onToggled: if (checked) page.variant = "P"
            }
            RadioButton {
                id: actualRadio
                visible: !page.monthMode
                objectName: "actualRadio"
                text: "Ist"
                checked: page.variant === "I"
                onToggled: if (checked) page.variant = "I"
            }
            CheckBox {
                id: previousBox
                visible: !page.monthMode
                objectName: "previousBox"
                text: "Vorwoche"
                checked: Store.showPreviousWeek
                onToggled: Store.showPreviousWeek = checked
                ToolTip.visible: hovered
                ToolTip.text: "Die Woche davor über dieser Woche zeigen"
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: -Styles.Primitives.stroke.thin
                IconButton {
                    iconName: "undo-2"
                    groupPosition: Styles.GroupStyle.Position.First
                    enabled: Store.undoLabel !== ""
                    toolTip: "Rückgängig: " + Store.undoLabel + " (Strg+Z)"
                    onClicked: page.undo()
                }
                IconButton {
                    iconName: "redo-2"
                    groupPosition: Styles.GroupStyle.Position.Last
                    enabled: Store.redoLabel !== ""
                    toolTip: "Wiederholen: " + Store.redoLabel + " (Strg+Y)"
                    onClicked: page.redo()
                }
            }

            IconButton {
                visible: !page.monthMode
                iconName: "copy"
                text: "Woche kopieren"
                enabled: page.hasAthlete && page.weekData.empty === false
                onClicked: if (page.savePanel()) Store.copyWeek(page.athleteId, page.monday, page.variant)
            }
            IconButton {
                visible: !page.monthMode
                iconName: "clipboard-paste"
                text: "Einfügen"
                enabled: page.hasAthlete && Store.clipboardLabel !== ""
                onClicked: {
                    if (!page.savePanel())
                        return
                    if (page.weekData.empty)
                        Store.pasteWeek(page.athleteId, page.monday, page.variant)
                    else
                        pasteConfirm.open()
                }
                ToolTip.visible: hovered && enabled
                ToolTip.text: "Kopierte Woche einfügen: " + Store.clipboardLabel
            }
            IconButton {
                objectName: "loadChartButton"
                visible: !page.monthMode
                iconName: "chart-line"
                text: "Verlauf"
                enabled: page.hasAthlete
                toolTip: "Belastungsverlauf: diese Woche im MAZ, gegen das ITP"
                onClicked: loadChart.show(page.athleteId, page.monday, "", 1)
            }
            IconButton {
                iconName: "printer"
                text: "Drucken"
                enabled: page.hasAthlete
                toolTip: page.monthMode ? "Den Monat drucken" : "Wochenplan drucken (Strg+P)"
                onClicked: page.monthMode ? Analysis.printReport(monthView.monthData.report) : page.printWeek()
            }
            IconButton {
                visible: !page.monthMode
                iconName: "file-down"
                text: "PDF"
                enabled: page.hasAthlete
                onClicked: {
                    page.saveNote()
                    pdfDialog.selectedFile = Store.suggestedPdfUrl(page.athleteId, page.monday)
                    pdfDialog.open()
                }
            }
        }
    }

    // The week, and beside it the session panel while one is open
    SplitView {
        id: split
        anchors.fill: parent
        orientation: Qt.Horizontal
        visible: page.hasAthlete
        handle: Rectangle {
            implicitWidth: 6
            color: SplitHandle.pressed || SplitHandle.hovered ? Styles.TokenInterface.semantics.stroke_subtle : "transparent"
        }

        Item {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 420

            MonthView {
                id: monthView
                objectName: "monthView"
                anchors.fill: parent
                anchors.margins: 8
                visible: page.monthMode
                athleteId: page.athleteId
                month: page.monthDay
                allAthletes: allBox.checked
                onWeekOpened: (m) => {
                    page.monday = m
                    page.showMonth(false)
                }
                onCompetitionRequested: (c, date) => competitionDialog.show(c, date, page.athleteId)
            }

            ColumnLayout {
                anchors.fill: parent
                // Lined up with the toolbar above (8 px from the window edge)
                anchors.margins: 8
                spacing: 8
                visible: !page.monthMode

                // Day columns with one row per session number, in an area that takes
                // the room left: the rows get its share in whole pixels, so all are
                // exactly as high (shared out by the layout, an odd height made one
                // row a pixel higher). The area, not the grid, fills: a grid fills
                // only as far as its cells do, which then set their heights apart.
                // A day without sessions is narrow; when even the narrow days do not
                // fit, the area scrolls sideways instead of squeezing the text.
                // Where the week stands: its MAZ and phase, the ITP's load, the next
                // competition
                RowLayout {
                    objectName: "cycleLine"
                    visible: page.cycleText !== "" || page.nextCompetitionText !== ""
                    Layout.fillWidth: true
                    spacing: 24
                    Label {
                        text: page.cycleText
                        visible: text !== ""
                        font.bold: true
                    }
                    Label {
                        text: page.nextCompetitionText
                        visible: text !== ""
                        color: Styles.TokenInterface.semantics.primary_default
                    }
                    Item { Layout.fillWidth: true }
                }

                Flickable {
                    id: gridArea
                    objectName: "gridArea"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: grid.minimumRows + bottomRoom
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: contentWidth > width
                    contentWidth: Math.max(width, grid.minimumWidth)
                    contentHeight: height
                    // Room for the scroll bar below the days while it shows
                    readonly property real bottomRoom: contentWidth > width ? hBar.height + 4 : 0
                    ScrollBar.horizontal: AppScrollBar { id: hBar }

                    GridLayout {
                        id: grid
                        width: gridArea.contentWidth
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 4

                        readonly property real headHeight: dayHeads.count > 0 && dayHeads.itemAt(0) ? dayHeads.itemAt(0).implicitHeight : 0
                        // The two weeks' labels, while the week before is shown
                        readonly property real labelsHeight: page.showPrevious ? 2 * (weekLabelHeight + rowSpacing) : 0
                        readonly property int weekLabelHeight: 18
                        readonly property int allRows: page.rows + page.previousRows
                        readonly property real minimumRows: headHeight + labelsHeight + allRows * (44 + rowSpacing)
                        readonly property int rowHeight: Math.max(44, Math.floor((gridArea.height - gridArea.bottomRoom - headHeight - labelsHeight - allRows * rowSpacing) / allRows))
                        readonly property real minimumWidth: {
                            let w = 6 * columnSpacing
                            for (let d = 1; d <= 7; ++d)
                                w += page.narrowDay(d) ? page.narrowWidth : page.wideMinimum
                            return w
                        }

                        Repeater {
                            id: dayHeads
                            model: 7
                            ColumnLayout {
                                required property int index
                                readonly property bool narrow: page.narrowDay(index + 1)
                                objectName: "dayHead" + (index + 1)
                                Layout.fillWidth: !narrow
                                Layout.preferredWidth: narrow ? page.narrowWidth : 1
                                Layout.minimumWidth: narrow ? page.narrowWidth : page.wideMinimum
                                Layout.maximumWidth: narrow ? page.narrowWidth : Number.POSITIVE_INFINITY
                                spacing: 0
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.narrow ? ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"][index] : Store.dayName(index + 1)
                                    font.bold: true
                                    color: page.todayDay === index + 1 ? Styles.TokenInterface.semantics.primary_default : Styles.TokenInterface.semantics.text_default
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: page.todayDay === index + 1 && !parent.narrow ? "heute, " + Store.dayDate(page.monday, index + 1)
                                                                                        : Store.dayDate(page.monday, index + 1)
                                    font.pixelSize: 11
                                    color: page.todayDay === index + 1 ? Styles.TokenInterface.semantics.primary_default : Styles.TokenInterface.semantics.text_muted
                                }
                            }
                        }

                        Label {
                            objectName: "previousLabel"
                            visible: page.showPrevious
                            Layout.columnSpan: 7
                            Layout.preferredHeight: grid.weekLabelHeight
                            text: "Vorwoche " + Store.weekLabel(page.previousMonday) + " · " + (page.previousVariant === "I" ? "Ist" : "Plan")
                                  + ((page.previousData.sessions || []).length === 0 ? " · keine Einheiten" : "")
                            font.pixelSize: 11
                            font.bold: true
                            color: Styles.TokenInterface.semantics.text_muted
                        }

                        Repeater {
                            id: previousCells
                            model: page.previousRows * 7
                            SessionCell {
                                required property int index
                                readonly property int day: index % 7 + 1
                                readonly property int row: Math.floor(index / 7) + 1
                                readonly property int number: page.previousNumberAt(day, row)
                                objectName: "previous" + day + "_" + number
                                readOnly: true
                                narrow: page.narrowDay(day)
                                opacity: 0.6
                                Layout.fillWidth: !narrow
                                Layout.preferredWidth: narrow ? page.narrowWidth : 1
                                Layout.minimumWidth: narrow ? page.narrowWidth : page.wideMinimum
                                Layout.maximumWidth: narrow ? page.narrowWidth : Number.POSITIVE_INFINITY
                                Layout.preferredHeight: grid.rowHeight
                                Layout.minimumHeight: 44
                                today: page.previousTodayDay === day
                                sessionNumber: number
                                session: number > 0 ? page.previousSessionAt(day, number) : null
                                onClicked: page.openPrevious()
                                onExerciseClicked: page.openPrevious()
                            }
                        }

                        Label {
                            objectName: "currentLabel"
                            visible: page.showPrevious
                            Layout.columnSpan: 7
                            Layout.preferredHeight: grid.weekLabelHeight
                            text: "Woche " + Store.weekLabel(page.monday) + " · " + (page.variant === "I" ? "Ist" : "Plan")
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Repeater {
                            id: cells
                            model: page.rows * 7
                            SessionCell {
                                required property int index
                                readonly property int day: index % 7 + 1
                                readonly property int row: Math.floor(index / 7) + 1
                                readonly property int number: page.numberAt(day, row)
                                objectName: "cell" + day + "_" + number
                                enabled: number > 0
                                narrow: page.narrowDay(day)
                                Layout.fillWidth: !narrow
                                Layout.preferredWidth: narrow ? page.narrowWidth : 1
                                Layout.minimumWidth: narrow ? page.narrowWidth : page.wideMinimum
                                Layout.maximumWidth: narrow ? page.narrowWidth : Number.POSITIVE_INFINITY
                                // Every row of sessions as high as the others, as in the
                                // old program, so the grid keeps its shape from week to
                                // week: exactly the rows' share, set rather than filled
                                // (a maximum would also cap the grid, which then shrank)
                                Layout.preferredHeight: grid.rowHeight
                                Layout.minimumHeight: 44
                                today: page.todayDay === day
                                selected: page.isEdited(day, number)
                                highlightExercise: page.editedExercise
                                sessionNumber: number
                                session: page.sessionAt(day, number)
                                onClicked: page.openSession(day, number)
                                onExerciseClicked: (exercise) => page.openExercise(exercise)
                                onDeleteRequested: page.askRemoveSession(day, number)
                                onMoveRequested: (days, sessions) => page.focusRow(day + days, row + sessions)
                                onCopyRequested: page.copySession(day, number)
                                onPasteRequested: page.pasteSession(day, number)
                                onMenuRequested: (exercise, x, y) => sessionMenu.show(this, day, number, exercise, x, y)
                                // Keep a cell reached by the keys in view
                                onActiveFocusChanged: {
                                    if (!activeFocus)
                                        return
                                    if (x < gridArea.contentX)
                                        gridArea.contentX = x
                                    else if (x + width > gridArea.contentX + gridArea.width)
                                        gridArea.contentX = x + width - gridArea.width
                                }
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Je Zeile: Übung  WH  MHG  BW  Wdh/Sätze beim BW  ·  Klick auf eine Übung bearbeitet sie für die ganze Woche, Klick daneben die Trainingseinheit  ·  Pfeiltasten, Enter, Entf  ·  F1: Hilfe"
                    font.pixelSize: 11
                    color: Styles.TokenInterface.semantics.text_muted
                    elide: Text.ElideRight
                    HoverHandler { id: legendHover }
                    ToolTip.visible: legendHover.hovered
                    ToolTip.delay: 400
                    ToolTip.text: ["WH", "MHG", "BW", "SG/ANZ"].map(t => Glossary.explain(t)).join("\n")
                }

                RowLayout {
                    Layout.fillWidth: true
                    // Only as high as its content: the note's fillHeight would
                    // otherwise make the row take room from the week
                    Layout.fillHeight: false
                    spacing: 8
                    Label {
                        text: "Bemerkung:"
                        Layout.alignment: Qt.AlignTop
                    }
                    ScrollView {
                        // No overshoot at the ends
                        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                        Layout.fillWidth: true
                        // As high as the row: its bottom on the line of Zusatzinfo's
                        Layout.fillHeight: true
                        Layout.preferredHeight: 56
                        TextArea {
                            id: noteField
                            wrapMode: TextEdit.Wrap
                            placeholderText: "Bemerkung zur Woche"
                            onTextChanged: if (activeFocus) page.noteDirty = true
                            onEditingFinished: page.saveNote()
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        // As wide as its widest item; the button's fillWidth would
                        // otherwise make it share the width with the note
                        Layout.fillWidth: false
                        spacing: 4
                        CheckBox {
                            id: injuredBox
                            text: "verletzt/krank"
                            onToggled: { page.noteDirty = true; page.saveNote() }
                        }
                        // As wide as the column: its right edge on the page's
                        IconButton {
                            Layout.fillWidth: true
                            iconName: "clipboard-list"
                            text: "Zusatzinfo"
                            toolTip: "Körpergewicht, Körperfett, Nahrungsergänzung …"
                            onClicked: dayInfoDialog.edit(page.athleteId, page.monday)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: page.hasAthlete ? (Store.dataVersion, Store.weekInfoSummary(page.athleteId, page.monday)) : ""
                    color: Styles.TokenInterface.semantics.text_muted
                    elide: Text.ElideRight
                }

                // Weekly summary K1-K7 as in the old program
                Frame {
                    Layout.fillWidth: true
                    padding: 0
                    background: Rectangle {
                        color: Styles.TokenInterface.semantics.background_elevated
                        border.color: Styles.TokenInterface.semantics.stroke_subtle
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            Layout.margins: 8
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: page.weekData.k17 || ""
                                font.bold: true
                                HoverHandler { id: k17Hover }
                                ToolTip.visible: k17Hover.hovered
                                ToolTip.delay: 400
                                ToolTip.text: "Alle Gruppen K1–K7: WH / MHG / Tonnage\n" + Glossary.explain("MHG")
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: page.weekData.k15 || ""
                                font.bold: true
                                HoverHandler { id: k15Hover }
                                ToolTip.visible: k15Hover.hovered
                                ToolTip.delay: 400
                                ToolTip.text: "Gruppen K1–K5: WH / MHG / Tonnage"
                            }
                        }
                        // Last week and the ITP's targets, and how far the week is off
                        Label {
                            objectName: "weekComparison"
                            visible: text !== ""
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.bottomMargin: 6
                            Layout.topMargin: -4
                            text: page.comparison.text
                            elide: Text.ElideRight
                            color: Math.abs(page.comparison.deviation) >= 10 ? Styles.TokenInterface.semantics.danger_default
                                                                             : Styles.TokenInterface.semantics.text_muted
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Styles.TokenInterface.semantics.stroke_subtle }
                        // The complexes side by side; where their lines do not
                        // fit (the panel open, a small window) in more rows
                        GridLayout {
                            id: groupGrid
                            objectName: "groupGrid"
                            Layout.fillWidth: true
                            columnSpacing: 0
                            rowSpacing: 0
                            columns: Math.max(1, Math.min(7, Math.floor(width / cellMinimum)))
                            // As wide as the longest line of the week, and its title
                            readonly property real cellMinimum: Math.max(90, lineMetrics.advanceWidth + 16)
                            TextMetrics {
                                id: lineMetrics
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                text: (page.weekData.groups || []).reduce(
                                          (a, g) => g.lines.reduce((b, l) => l.length > b.length ? l : b, a), "")
                            }
                            Repeater {
                                model: page.weekData.groups || []
                                // All cells of a row stretch to the tallest one;
                                // lines on the left and above separate them.
                                Item {
                                    required property var modelData
                                    required property int index
                                    objectName: "group" + (index + 1)
                                    clip: true
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: Math.max(54, groupColumn.implicitHeight + 10)

                                    Rectangle {
                                        visible: index % groupGrid.columns > 0
                                        width: 1
                                        height: parent.height
                                        color: Styles.TokenInterface.semantics.stroke_subtle
                                    }
                                    Rectangle {
                                        visible: index >= groupGrid.columns
                                        width: parent.width
                                        height: 1
                                        color: Styles.TokenInterface.semantics.stroke_subtle
                                    }

                                    ColumnLayout {
                                        id: groupColumn
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.topMargin: 4
                                        spacing: 1
                                        Label {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.title
                                            font.bold: true
                                            HoverHandler { id: groupHover }
                                            ToolTip.visible: groupHover.hovered
                                            ToolTip.delay: 400
                                            ToolTip.text: Glossary.group(index + 1)
                                                          + "\nJe Zeile: Übung  WH  MHG  BW  Wdh/Sätze beim BW"
                                        }
                                        Label {
                                            objectName: "groupComparison" + (index + 1)
                                            Layout.alignment: Qt.AlignHCenter
                                            visible: text !== ""
                                            text: page.groupComparison(index)
                                            font.pixelSize: 11
                                            color: Styles.TokenInterface.semantics.text_muted
                                        }
                                        Repeater {
                                            model: modelData.lines
                                            Label {
                                                required property string modelData
                                                Layout.alignment: Qt.AlignHCenter
                                                text: modelData
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Where the session panel sits beside the week
        Item {
            id: panelSlot
            objectName: "panelSlot"
            visible: page.activeEditor !== null && !panelSettings.floating
            SplitView.preferredWidth: panelSettings.dockWidth
            SplitView.minimumWidth: 420
            onWidthChanged: if (visible && width > 0) panelSettings.dockWidth = width
        }
    }

    Settings {
        id: viewSettings
        category: "week"
        property bool monthMode: false
    }

    LoadChartDialog {
        id: loadChart
        objectName: "loadChartDialog"
    }

    CompetitionDateDialog {
        id: competitionDialog
        objectName: "competitionDialog"
    }

    Settings {
        id: panelSettings
        category: "sessionPanel"
        property bool floating: false
        property real dockWidth: 560
        property int windowX: -1
        property int windowY: -1
        property int windowWidth: 640
        property int windowHeight: 780
    }

    SessionEditor {
        id: sessionEditor
        objectName: "sessionEditor"
        parent: floating ? floatWindow.contentItem : panelSlot
        anchors.fill: parent
        visible: opened
        floating: panelSettings.floating
        onFloatingToggled: page.toggleFloating(sessionEditor)
        // Back to the session's cell, when it is in the week shown
        onClosed: {
            if (athleteId === page.athleteId && monday === page.monday && variant === page.variant)
                page.focusSession(day, number)
        }
        Connections {
            target: Store
            // Changed elsewhere (undo, the TÜ dialog, Ist = Plan in the menu):
            // show it, unless there are changes of its own
            function onDataVersionChanged() {
                if (sessionEditor.opened && !sessionEditor.dirty && !sessionEditor.saving)
                    sessionEditor.reload()
            }
        }
    }

    // Erfassung TÜ, the panel's second view
    ExerciseEditor {
        id: exerciseEditor
        objectName: "exerciseEditor"
        parent: floating ? floatWindow.contentItem : panelSlot
        anchors.fill: parent
        visible: opened
        floating: panelSettings.floating
        onFloatingToggled: page.toggleFloating(exerciseEditor)
        onClosed: {
            if (athleteId === page.athleteId && monday === page.monday && variant === page.variant)
                page.focusSession(1, 1)
        }
        Connections {
            target: Store
            function onDataVersionChanged() {
                if (exerciseEditor.opened && !exerciseEditor.dirty && !exerciseEditor.saving)
                    exerciseEditor.reload()
            }
        }
    }

    function toggleFloating(editor) {
        panelSettings.floating = !panelSettings.floating
        // Docked again: the keys go to the week's window
        if (!panelSettings.floating)
            Qt.callLater(() => {
                page.Window.window.requestActivate()
                editor.forceActiveFocus()
            })
    }

    // The panel in a window of its own, for a second screen
    ApplicationWindow {
        id: floatWindow
        objectName: "floatWindow"
        title: page.activeEditor ? page.activeEditor.title : ""
        visible: page.activeEditor !== null && panelSettings.floating
        minimumWidth: 460
        minimumHeight: 420
        width: panelSettings.windowWidth
        height: panelSettings.windowHeight
        Component.onCompleted: {
            if (panelSettings.windowX >= 0) {
                x = panelSettings.windowX
                y = panelSettings.windowY
            }
        }
        onXChanged: if (visible) panelSettings.windowX = x
        onYChanged: if (visible) panelSettings.windowY = y
        onWidthChanged: if (visible) panelSettings.windowWidth = width
        onHeightChanged: if (visible) panelSettings.windowHeight = height
        // Closing the window closes the session, saved
        onClosing: (close) => { close.accepted = page.closePanel() }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !page.hasAthlete
        spacing: 12
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Store.athletes.length === 0 ? "Noch keine Daten vorhanden." : "Bitte einen Sportler wählen."
            font.pixelSize: 18
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            visible: Store.athletes.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "Über „Daten“ › „Importieren“ die Datensicherung des alten Programms (winwotaxp.bak) einlesen\noder unter „Sportler“ einen neuen Sportler anlegen."
            color: Styles.TokenInterface.semantics.text_muted
        }
    }



    DayInfoDialog {
        id: dayInfoDialog
    }

    ExerciseHistoryDialog {
        id: historyDialog
    }

    AppDialog {
        id: pasteConfirm
        title: "Woche ersetzen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: "Die angezeigte Woche enthält schon Trainingseinheiten.\nSie werden durch die kopierte Woche ersetzt:\n" + Store.clipboardLabel
        }
        onAccepted: if (page.savePanel()) Store.pasteWeek(page.athleteId, page.monday, page.variant)
    }

    // Right click on a session or one of its lines
    Menu {
        id: sessionMenu
        objectName: "sessionMenu"
        property int day: 1
        property int number: 1
        property int exercise: 0
        readonly property bool filled: page.sessionAt(day, number) !== null
        readonly property bool hasPlan: page.hasAthlete && opened
                                        && Store.session(page.athleteId, page.monday, "P", day, number).exists

        function show(cell, d, n, ex, x, y) {
            day = d
            number = n
            exercise = ex
            popup(cell, x, y)
        }

        KeyMenuItem {
            text: "Bearbeiten"
            keys: "Enter"
            onTriggered: page.openSession(sessionMenu.day, sessionMenu.number)
        }
        MenuItem {
            visible: sessionMenu.exercise > 0
            height: visible ? implicitHeight : 0
            text: "Übung " + sessionMenu.exercise + " für die Woche bearbeiten"
            onTriggered: page.openExercise(sessionMenu.exercise)
        }
        MenuItem {
            visible: sessionMenu.exercise > 0
            height: visible ? implicitHeight : 0
            text: "Verlauf von Übung " + sessionMenu.exercise
            onTriggered: historyDialog.show(page.athleteId, page.monday, page.variant, sessionMenu.exercise, false)
        }
        MenuSeparator {}
        MenuItem {
            text: "Weitere Einheit an diesem Tag"
            enabled: page.hasAthlete && page.canAddSession(sessionMenu.day)
            onTriggered: page.addSession(sessionMenu.day)
        }
        MenuSeparator {}
        KeyMenuItem {
            text: "Kopieren"
            enabled: sessionMenu.filled
            onTriggered: page.copySession(sessionMenu.day, sessionMenu.number)
            keys: "Strg+C"
        }
        KeyMenuItem {
            text: Store.sessionClipboardLabel !== "" ? "Einfügen: " + Store.sessionClipboardLabel
                                                     : "Einfügen"
            enabled: Store.sessionClipboardLabel !== ""
            onTriggered: page.pasteSession(sessionMenu.day, sessionMenu.number)
            keys: "Strg+V"
        }
        MenuItem {
            // Ist = Plan: the planned session becomes the actual one
            text: page.variant === "P" ? "Als Ist übernehmen" : "Ist = Plan"
            enabled: sessionMenu.hasPlan
            onTriggered: if (page.savePanel()) Store.planToActual(page.athleteId, page.monday, sessionMenu.day, sessionMenu.number)
        }
        KeyMenuItem {
            text: "Löschen"
            enabled: sessionMenu.filled
            onTriggered: page.askRemoveSession(sessionMenu.day, sessionMenu.number)
            keys: "Entf"
        }
        MenuSeparator {}
        KeyMenuItem {
            text: Store.undoLabel !== "" ? "Rückgängig: " + Store.undoLabel : "Rückgängig"
            enabled: Store.undoLabel !== ""
            onTriggered: page.undo()
            keys: "Strg+Z"
        }
        KeyMenuItem {
            text: Store.redoLabel !== "" ? "Wiederholen: " + Store.redoLabel : "Wiederholen"
            enabled: Store.redoLabel !== ""
            onTriggered: page.redo()
            keys: "Strg+Y"
        }
    }

    AppDialog {
        id: removeConfirm
        objectName: "removeConfirm"
        property int day: 1
        property int number: 1
        title: "Trainingseinheit löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: Store.dayName(removeConfirm.day) + ", " + removeConfirm.number + ". TE ("
                  + (page.variant === "P" ? "Plan" : "Ist") + ") wird mit allen Übungen gelöscht."
        }
        onAccepted: if (page.savePanel()) Store.removeSession(page.athleteId, page.monday, page.variant,
                                                              removeConfirm.day, removeConfirm.number)
        onClosed: page.focusSession(day, number)
    }

    FileDialog {
        id: pdfDialog
        title: "Wochenplan als PDF speichern"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "pdf"
        nameFilters: ["PDF (*.pdf)"]
        onAccepted: {
            const err = Store.exportPdf(page.athleteId, page.monday, page.variant, selectedFile, true)
            if (err !== "") {
                errorDialog.text = err
                errorDialog.open()
            }
        }
    }

    AppDialog {
        id: errorDialog
        property alias text: errorLabel.text
        title: "Fehler"
        standardButtons: Dialog.Ok
        Label { id: errorLabel }
    }
}
