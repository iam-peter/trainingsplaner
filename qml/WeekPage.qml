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

    header: ToolBar {
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
                ToolTip.text: "Vorige Woche"
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
                ToolTip.text: "Nächste Woche"
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
                onClicked: {
                    page.saveNote()
                    Store.printWeek(page.athleteId, page.monday, page.variant)
                }
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
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: Store.dayDate(page.monday, index + 1)
                        font.pixelSize: 11
                        color: palette.placeholderText
                    }
                }
            }

            Repeater {
                model: page.threeSessions ? 21 : 14
                SessionCell {
                    required property int index
                    readonly property int day: index % 7 + 1
                    readonly property int number: Math.floor(index / 7) + 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    sessionNumber: number
                    session: page.sessionAt(day, number)
                    onClicked: page.openSession(day, number)
                    onExerciseClicked: (exercise) => page.openExercise(exercise)
                }
            }
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
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: page.weekData.k15 || ""
                        font.bold: true
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
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            text: "Die angezeigte Woche enthält schon Trainingseinheiten.\nSie werden durch die kopierte Woche ersetzt:\n" + Store.clipboardLabel
        }
        onAccepted: Store.pasteWeek(page.athleteId, page.monday, page.variant)
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
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
        Label { id: errorLabel }
    }
}
