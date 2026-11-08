import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

Page {
    id: page

    property string athleteId
    property string monday: Store.mondayOf(Store.today())
    property string variant: "P"
    property bool threeSessions: false
    property var weekData: ({})

    // The week the note field belongs to, so it is saved to the right week
    // even after the selection has changed.
    property var noteOwner: null

    readonly property bool hasAthlete: athleteId !== ""

    function selectDefaultAthlete() {
        if (athleteId === "" && Store.athletes.length > 0)
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
        noteField.text = weekData.note
        injuredBox.checked = weekData.injured
        noteOwner = { athleteId: athleteId, monday: monday, variant: variant }
        // Show the third row automatically when the week uses it.
        for (const s of weekData.sessions) {
            if (s.number === 3)
                threeSessions = true
        }
    }

    // 1-7 when today is in the shown week, else 0
    readonly property int todayDay: {
        const t = Store.today()
        return Store.mondayOf(t) === monday ? (new Date(t + "T12:00:00").getDay() + 6) % 7 + 1 : 0
    }

    // How much room a row of sessions gets: by its longest session, so an
    // empty row of first sessions stays small
    function rowWeight(number) {
        let lines = 0
        for (let d = 1; d <= 7; ++d) {
            const s = sessionAt(d, number)
            if (s)
                lines = Math.max(lines, s.entries.length + 2)
        }
        return Math.max(lines, 2)
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

    function focusSession(day, number) {
        const rows = threeSessions ? 3 : 2
        day = Math.min(7, Math.max(1, day))
        number = Math.min(rows, Math.max(1, number))
        cells.itemAt((number - 1) * 7 + day - 1).forceActiveFocus()
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

    onAthleteIdChanged: reload()
    onMondayChanged: reload()
    onVariantChanged: reload()
    Connections {
        target: Store
        function onDataVersionChanged() { page.reload() }
        function onAthletesChanged() {
            if (page.athleteId !== "" && !Store.athletes.some(a => a.id === page.athleteId)) {
                page.noteOwner = null
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
            spacing: 6

            ComboBox {
                id: athleteBox
                Layout.preferredWidth: 220
                model: Store.selectableAthletes
                textRole: "displayName"
                valueRole: "id"
                currentIndex: indexOfValue(page.athleteId)
                displayText: currentIndex < 0 ? "Sportler wählen" : currentText
                onActivated: page.athleteId = currentValue
            }

            ToolSeparator {}

            IconButton {
                iconName: "chevron-left"
                onClicked: page.monday = Store.addWeeks(page.monday, -1)
                ToolTip.visible: hovered
                ToolTip.text: "Vorige Woche (Strg+←)"
            }
            TextField {
                id: weekField
                Layout.preferredWidth: 80
                horizontalAlignment: TextInput.AlignHCenter
                text: Store.weekLabel(page.monday)
                font.bold: true
                onAccepted: {
                    const m = Store.weekFromLabel(text)
                    if (m !== "")
                        page.monday = m
                    text = Qt.binding(() => Store.weekLabel(page.monday))
                    focus = false
                }
                ToolTip.visible: activeFocus
                ToolTip.text: "Woche/Jahr eingeben, z.B. 46/2026, dann Enter"
            }
            IconButton {
                iconName: "chevron-right"
                onClicked: page.monday = Store.addWeeks(page.monday, 1)
                ToolTip.visible: hovered
                ToolTip.text: "Nächste Woche (Strg+→)"
            }
            IconButton {
                id: calendarButton
                iconName: "calendar-days"
                toolTip: "Woche im Kalender wählen"
                onClicked: calendar.open()
                WeekCalendar {
                    id: calendar
                    y: calendarButton.height + 2
                    monday: page.monday
                    onPicked: (m) => page.monday = m
                }
            }
            IconButton {
                iconName: "calendar"
                text: "Heute"
                onClicked: page.monday = Store.mondayOf(Store.today())
            }
            Label {
                text: Store.weekRange(page.monday)
                color: palette.placeholderText
            }

            ToolSeparator {}

            RadioButton {
                text: "Plan"
                checked: page.variant === "P"
                onToggled: if (checked) page.variant = "P"
            }
            RadioButton {
                text: "Ist"
                checked: page.variant === "I"
                onToggled: if (checked) page.variant = "I"
            }
            CheckBox {
                text: "3 TE"
                checked: page.threeSessions
                onToggled: page.threeSessions = checked
                ToolTip.visible: hovered
                ToolTip.text: "Dritte Trainingseinheit pro Tag anzeigen"
            }

            Item { Layout.fillWidth: true }

            IconButton {
                iconName: "undo-2"
                enabled: Store.undoLabel !== ""
                toolTip: "Rückgängig: " + Store.undoLabel + " (Strg+Z)"
                onClicked: page.show(Store.undo())
            }
            IconButton {
                iconName: "redo-2"
                enabled: Store.redoLabel !== ""
                toolTip: "Wiederholen: " + Store.redoLabel + " (Strg+Y)"
                onClicked: page.show(Store.redo())
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
                text: "Drucken…"
                enabled: page.hasAthlete
                toolTip: "Wochenplan drucken (Strg+P)"
                onClicked: page.printWeek()
            }
            IconButton {
                iconName: "file-down"
                text: "PDF…"
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
        anchors.margins: 10
        spacing: 8
        visible: page.hasAthlete

        // Day columns with one row per session number
        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: 7
                ColumnLayout {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 0
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: Store.dayName(index + 1)
                        font.bold: true
                        color: page.todayDay === index + 1 ? Theme.accent : palette.windowText
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: page.todayDay === index + 1 ? "heute, " + Store.dayDate(page.monday, index + 1)
                                                           : Store.dayDate(page.monday, index + 1)
                        font.pixelSize: 11
                        color: page.todayDay === index + 1 ? Theme.accent : palette.placeholderText
                    }
                }
            }

            Repeater {
                id: cells
                model: page.threeSessions ? 21 : 14
                SessionCell {
                    required property int index
                    readonly property int day: index % 7 + 1
                    readonly property int number: Math.floor(index / 7) + 1
                    objectName: "cell" + day + "_" + number
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.minimumHeight: 44
                    Layout.verticalStretchFactor: page.rowWeight(number)
                    today: page.todayDay === day
                    sessionNumber: number
                    session: page.sessionAt(day, number)
                    onClicked: page.openSession(day, number)
                    onExerciseClicked: (exercise) => page.openExercise(exercise)
                    onDeleteRequested: page.askRemoveSession(day, number)
                    onMoveRequested: (days, sessions) => page.focusSession(day + days, number + sessions)
                    onCopyRequested: page.copySession(day, number)
                    onPasteRequested: page.pasteSession(day, number)
                    onMenuRequested: (exercise, x, y) => sessionMenu.show(this, day, number, exercise, x, y)
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Je Zeile: Übung  WH  MHG  BW  Wdh/Sätze beim BW  ·  Klick auf eine Übung bearbeitet sie für die ganze Woche, Klick daneben die Trainingseinheit  ·  Pfeiltasten, Enter, Entf  ·  F1: Hilfe"
            font.pixelSize: 11
            color: palette.placeholderText
            elide: Text.ElideRight
            HoverHandler { id: legendHover }
            ToolTip.visible: legendHover.hovered
            ToolTip.delay: 400
            ToolTip.text: ["WH", "MHG", "BW", "SG/ANZ"].map(t => Glossary.explain(t)).join("\n")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: "Bemerkung:"
                Layout.alignment: Qt.AlignTop
            }
            ScrollView {
                Layout.fillWidth: true
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
                spacing: 2
                CheckBox {
                    id: injuredBox
                    text: "verletzt/krank"
                    onToggled: page.saveNote()
                }
                IconButton {
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
            color: palette.placeholderText
            elide: Text.ElideRight
        }

        // Weekly summary K1-K7 as in the old program
        Frame {
            Layout.fillWidth: true
            padding: 0
            background: Rectangle {
                color: palette.base
                border.color: palette.mid
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 6
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
                Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }
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
                                color: palette.mid
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
            text: "Über „Daten“ › „Importieren…“ die Datensicherung des alten Programms (winwotaxp.bak) einlesen\noder unter „Sportler“ einen neuen Sportler anlegen."
            color: palette.placeholderText
        }
    }

    SessionDialog {
        id: sessionDialog
    }

    ExerciseWeekDialog {
        id: exerciseDialog
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

        // As wide as the longest entry (Menu's own width is fixed)
        width: {
            let w = 200
            for (let i = 0; i < count; ++i) {
                const it = itemAt(i)
                if (it && it.visible)
                    w = Math.max(w, it.implicitWidth)
            }
            return w + leftPadding + rightPadding
        }

        function show(cell, d, n, ex, x, y) {
            day = d
            number = n
            exercise = ex
            popup(cell, x, y)
        }

        KeyMenuItem {
            text: "Bearbeiten…"
            keys: "Enter"
            onTriggered: page.openSession(sessionMenu.day, sessionMenu.number)
        }
        MenuItem {
            visible: sessionMenu.exercise > 0
            height: visible ? implicitHeight : 0
            text: "Übung " + sessionMenu.exercise + " für die Woche bearbeiten…"
            onTriggered: page.openExercise(sessionMenu.exercise)
        }
        MenuItem {
            visible: sessionMenu.exercise > 0
            height: visible ? implicitHeight : 0
            text: "Verlauf von Übung " + sessionMenu.exercise + "…"
            onTriggered: historyDialog.show(page.athleteId, page.monday, page.variant, sessionMenu.exercise, false)
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
            text: "Löschen…"
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
