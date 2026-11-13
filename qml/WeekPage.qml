import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
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
    // Days with a session in either variant
    readonly property var usedDays: dayNumbers.map(d => d.length > 0)
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

    function saveNote() {
        if (noteOwner === null)
            return
        Store.saveWeekNote(noteOwner.athleteId, noteOwner.monday, noteOwner.variant,
                           noteField.text, injuredBox.checked)
    }

    function reload() {
        saveNote()
        if (!hasAthlete) {
            weekData = {}
            noteOwner = null
            return
        }
        weekData = Store.week(athleteId, monday, variant)
        otherWeek = Store.week(athleteId, monday, variant === "P" ? "I" : "P")
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

    function openExercise(exercise) {
        if (!hasAthlete)
            return
        saveNote()
        exerciseDialog.edit(athleteId, monday, variant, exercise)
    }

    // The cell of a day's session, by its number
    function focusSession(day, number) {
        day = Math.min(7, Math.max(1, day))
        for (let row = 1; row <= rows; ++row) {
            if (numberAt(day, row) === number) {
                focusRow(day, row)
                return
            }
        }
        focusRow(day, number)
    }

    // The cell in a day's row, moved to by the arrow keys
    function focusRow(day, row) {
        day = Math.min(7, Math.max(1, day))
        row = Math.min(rows, Math.max(1, row))
        cells.itemAt((row - 1) * 7 + day - 1).forceActiveFocus()
    }

    function askRemoveSession(day, number) {
        if (!hasAthlete || !sessionAt(day, number))
            return
        removeConfirm.day = day
        removeConfirm.number = number
        removeConfirm.open()
    }

    function copySession(day, number) {
        if (hasAthlete && sessionAt(day, number))
            Store.copySession(athleteId, monday, variant, day, number)
    }

    function pasteSession(day, number) {
        if (hasAthlete && Store.sessionClipboardLabel !== "")
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
    readonly property bool shortcutsActive: visible && DialogStack.open === 0
    Shortcut {
        sequence: "Ctrl+Left"
        enabled: page.shortcutsActive
        onActivated: page.monday = Store.addWeeks(page.monday, -1)
    }
    Shortcut {
        sequence: "Ctrl+Right"
        enabled: page.shortcutsActive
        onActivated: page.monday = Store.addWeeks(page.monday, 1)
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
        sessionDialog.edit(athleteId, monday, variant, day, number)
    }

    onAthleteIdChanged: { extraRows = 0; reload() }
    onMondayChanged: { extraRows = 0; reload() }
    onVariantChanged: reload()
    Connections {
        target: Store
        function onDataVersionChanged() { page.reload() }
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

            // The week between its arrows, as one group with shared edges
            RowLayout {
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
                onClicked: page.monday = Store.mondayOf(Store.today())
            }
            Label {
                text: Store.weekRange(page.monday)
                color: Styles.TokenInterface.semantics.text_muted
            }

            ToolSeparator {}

            RadioButton {
                id: planRadio
                objectName: "planRadio"
                text: "Plan"
                checked: page.variant === "P"
                onToggled: if (checked) page.variant = "P"
            }
            RadioButton {
                id: actualRadio
                objectName: "actualRadio"
                text: "Ist"
                checked: page.variant === "I"
                onToggled: if (checked) page.variant = "I"
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: -Styles.Primitives.stroke.thin
                IconButton {
                    iconName: "undo-2"
                    groupPosition: Styles.GroupStyle.Position.First
                    enabled: Store.undoLabel !== ""
                    toolTip: "Rückgängig: " + Store.undoLabel + " (Strg+Z)"
                    onClicked: page.show(Store.undo())
                }
                IconButton {
                    iconName: "redo-2"
                    groupPosition: Styles.GroupStyle.Position.Last
                    enabled: Store.redoLabel !== ""
                    toolTip: "Wiederholen: " + Store.redoLabel + " (Strg+Y)"
                    onClicked: page.show(Store.redo())
                }
            }

            IconButton {
                iconName: "copy"
                text: "Woche kopieren"
                enabled: page.hasAthlete && page.weekData.empty === false
                onClicked: Store.copyWeek(page.athleteId, page.monday, page.variant)
            }
            IconButton {
                iconName: "clipboard-paste"
                text: "Einfügen"
                enabled: page.hasAthlete && Store.clipboardLabel !== ""
                onClicked: {
                    if (page.weekData.empty)
                        Store.pasteWeek(page.athleteId, page.monday, page.variant)
                    else
                        pasteConfirm.open()
                }
                ToolTip.visible: hovered && enabled
                ToolTip.text: "Kopierte Woche einfügen: " + Store.clipboardLabel
            }
            IconButton {
                iconName: "printer"
                text: "Drucken"
                enabled: page.hasAthlete
                toolTip: "Wochenplan drucken (Strg+P)"
                onClicked: page.printWeek()
            }
            IconButton {
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

    ColumnLayout {
        anchors.fill: parent
        // Lined up with the toolbar above (8 px from the window edge)
        anchors.margins: 8
        spacing: 8
        visible: page.hasAthlete

        // Day columns with one row per session number, in an area that takes
        // the room left: the rows get its share in whole pixels, so all are
        // exactly as high (shared out by the layout, an odd height made one
        // row a pixel higher). The area, not the grid, fills: a grid fills
        // only as far as its cells do, which then set their heights apart.
        // A day without sessions is narrow; when even the narrow days do not
        // fit, the area scrolls sideways instead of squeezing the text.
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
                readonly property real minimumRows: headHeight + page.rows * (44 + rowSpacing)
                readonly property int rowHeight: Math.max(44, Math.floor((gridArea.height - gridArea.bottomRoom - headHeight - page.rows * rowSpacing) / page.rows))
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
                    onToggled: page.saveNote()
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
                Rectangle { Layout.fillWidth: true; height: 1; color: Styles.TokenInterface.semantics.stroke_subtle }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: page.weekData.groups || []
                        // All cells stretch to the tallest one; a line on
                        // the left separates them.
                        Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Math.max(54, groupColumn.implicitHeight + 10)

                            Rectangle {
                                visible: index > 0
                                width: 1
                                height: parent.height
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

    SessionDialog {
        id: sessionDialog
        objectName: "sessionDialog"
    }

    ExerciseWeekDialog {
        id: exerciseDialog
        objectName: "exerciseDialog"
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
        onAccepted: Store.pasteWeek(page.athleteId, page.monday, page.variant)
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
            onTriggered: Store.planToActual(page.athleteId, page.monday, sessionMenu.day, sessionMenu.number)
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
            onTriggered: page.show(Store.undo())
            keys: "Strg+Z"
        }
        KeyMenuItem {
            text: Store.redoLabel !== "" ? "Wiederholen: " + Store.redoLabel : "Wiederholen"
            enabled: Store.redoLabel !== ""
            onTriggered: page.show(Store.redo())
            keys: "Strg+Y"
        }
    }

    AppDialog {
        id: removeConfirm
        property int day: 1
        property int number: 1
        title: "Trainingseinheit löschen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: Store.dayName(removeConfirm.day) + ", " + removeConfirm.number + ". TE ("
                  + (page.variant === "P" ? "Plan" : "Ist") + ") wird mit allen Übungen gelöscht."
        }
        onAccepted: Store.removeSession(page.athleteId, page.monday, page.variant,
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
