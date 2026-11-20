import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The month, in place of the coach's paper calendar: weeks as rows with
// their load (h / m / g from the ITP) and reps planned / done, the days
// with their sessions and competitions, and the coming competitions at
// the side. With "Alle Sportler" only the competitions, of everyone.
Item {
    id: view

    property string athleteId
    // Any day of the month shown, "yyyy-MM-dd"
    property string month
    property bool allAthletes: false
    property var monthData: ({})

    // A week to open in the week view
    signal weekOpened(string monday)
    // A competition date to enter (date "" = none chosen) or to change
    signal competitionRequested(var competition, string date)
    // A Lehrgang or Diagnostik to change (its id)
    signal eventRequested(string id)

    // What the calendar and the list show
    property bool showCompetitions: true
    property bool showLehrgang: true
    property bool showDiagnostik: true
    function shown(item) {
        return item.isEvent ? (item.kind === 2 ? showDiagnostik : showLehrgang) : showCompetitions
    }

    function reload() {
        monthData = month !== "" && (allAthletes || athleteId !== "") ? Store.month(athleteId, month, allAthletes) : {}
    }
    // Hidden (the week shown): reloaded when it shows
    onAthleteIdChanged: if (visible) reload()
    onMonthChanged: if (visible) reload()
    onAllAthletesChanged: if (visible) reload()
    onVisibleChanged: if (visible) reload()
    Component.onCompleted: reload()
    Connections {
        target: Store
        function onDataVersionChanged() { if (view.visible) view.reload() }
    }
    Connections {
        target: Plan
        function onChanged() { if (view.visible) view.reload() }
    }

    readonly property var s: Styles.TokenInterface.semantics
    readonly property var loadColor: ({ h: "#5b6b7f", m: "#9aa8b8", g: "#d5dde6" })
    // The phases' fills are the same in every scheme, so their labels' are
    // too: dark on the light GLP, white on the others
    readonly property var phaseColor: ({ GLP: "#c3cfdb", ABP: "#8aa1b8", LAP: "#4d6680" })
    readonly property var phaseTextColor: ({ GLP: "#1f2a36", ABP: "white", LAP: "white" })
    // Between the week rows; the bands close this gap where they go on
    readonly property real weekSpacing: 3

    // The plan's bands, as IDA lays them over its calendar: the MAZ, and
    // under it its phases, each over the weeks it spans
    function bandKey(week, kind) {
        const maz = week && week.maz && week.maz.id ? week.maz.id : ""
        if (kind === "maz" || maz === "")
            return maz
        return week.phaseShort ? maz + "|" + week.phaseShort : ""
    }
    function joins(i, j, kind) {
        const weeks = monthData.weeks || []
        if (j < 0 || j >= weeks.length)
            return false
        const key = bandKey(weeks[i], kind)
        return key !== "" && key === bandKey(weeks[j], kind)
    }
    // The weeks of the band from week i on (its label is drawn over them)
    function runLength(i, kind) {
        let n = 1
        while (joins(i, i + n, kind))
            ++n
        return n
    }

    // One week's piece of a band: joined to the next above and below, its
    // label from the band's first week of the month over all its weeks
    component BandPiece: Item {
        id: piece
        property int index
        property string kind
        property color color
        property color textColor
        property string label
        property string tip
        readonly property real rowSpacing: view.weekSpacing
        readonly property bool above: view.joins(index, index - 1, kind)
        readonly property bool below: view.joins(index, index + 1, kind)
        readonly property bool on: view.bandKey((view.monthData.weeks || [])[index], kind) !== ""
        Layout.fillHeight: true
        Rectangle {
            visible: piece.on
            anchors.fill: parent
            anchors.topMargin: piece.above ? -piece.rowSpacing : 0
            anchors.bottomMargin: piece.below ? -piece.rowSpacing : 0
            radius: 3
            color: piece.color
            // Square where it goes on
            Rectangle { visible: piece.above; width: parent.width; height: 4; color: piece.color }
            Rectangle { visible: piece.below; width: parent.width; height: 4; anchors.bottom: parent.bottom; color: piece.color }
        }
        Item {
            visible: piece.on && !piece.above
            width: piece.width
            height: view.runLength(piece.index, piece.kind) * (piece.height + piece.rowSpacing) - piece.rowSpacing
            Label {
                objectName: piece.kind + "Label"
                anchors.centerIn: parent
                width: parent.height - 6
                rotation: -90
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: 11
                font.bold: piece.kind === "phase"
                color: piece.textColor
                text: piece.label
            }
            HoverHandler { id: bandHover }
            ToolTip.visible: bandHover.hovered && piece.tip !== ""
            ToolTip.text: piece.tip
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: view.weekSpacing

            // Column heads
            RowLayout {
                Layout.fillWidth: true
                spacing: 3
                Item { Layout.preferredWidth: 40; visible: !view.allAthletes }
                Label { Layout.preferredWidth: 58; text: "KW · Bel."; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                Label { Layout.preferredWidth: 92; text: "WH Plan / Ist"; font.bold: true; visible: !view.allAthletes }
                Repeater {
                    model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    Label {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: modelData
                        font.bold: true
                    }
                }
            }

            Repeater {
                id: weekRows
                model: view.monthData.weeks || []
                RowLayout {
                    id: weekRow
                    required property var modelData
                    required property int index
                    objectName: "monthWeek" + index
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    spacing: 3

                    // The MAZ and its phase down the left edge, as bands
                    // over their weeks; each row above the next
                    // (a label goes down over the rows after its first)
                    z: (view.monthData.weeks || []).length - index
                    RowLayout {
                        Layout.preferredWidth: 40
                        Layout.fillHeight: true
                        visible: !view.allAthletes
                        spacing: 2
                        BandPiece {
                            objectName: "mazBand"
                            Layout.preferredWidth: 16
                            index: weekRow.index
                            kind: "maz"
                            color: view.s.stroke_subtle
                            textColor: view.s.text_default
                            label: weekRow.modelData.maz ? weekRow.modelData.maz.short || "" : ""
                            tip: weekRow.modelData.maz && weekRow.modelData.maz.id
                                 ? "MAZ " + weekRow.modelData.maz.name + " (" + weekRow.modelData.maz.weeks + ")" : ""
                        }
                        BandPiece {
                            objectName: "phaseBand"
                            Layout.preferredWidth: 22
                            index: weekRow.index
                            kind: "phase"
                            color: view.phaseColor[weekRow.modelData.phaseShort] || "transparent"
                            textColor: view.phaseTextColor[weekRow.modelData.phaseShort] || view.s.text_default
                            label: weekRow.modelData.phaseShort || ""
                            tip: weekRow.modelData.phase || ""
                        }
                    }

                    // Week number and load; a click opens the week
                    Rectangle {
                        objectName: "weekCell"
                        Layout.preferredWidth: 58
                        Layout.fillHeight: true
                        radius: 4
                        color: view.s.cell_default
                        border.color: weekHover.hovered ? view.s.stroke_focus : view.s.cell_border
                        border.width: weekHover.hovered ? 2 : 1
                        HoverHandler { id: weekHover; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: view.weekOpened(weekRow.modelData.monday)
                        }
                        ToolTip.visible: weekHover.hovered
                        ToolTip.text: "Woche " + weekRow.modelData.label + " öffnen"
                                      + (weekRow.modelData.countdown > 0
                                         ? "\nTr.-Wo. " + weekRow.modelData.countdown
                                           + (weekRow.modelData.countdown === 1 ? ": Woche des Hauptwettkampfs"
                                                                                 : ": noch " + weekRow.modelData.countdown
                                                                                   + " Wochen bis zum Hauptwettkampf")
                                         : "")
                                      + (weekRow.modelData.position ? "\nWK-Lage " + weekRow.modelData.position : "")
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: weekRow.modelData.label
                                font.bold: true
                                font.pixelSize: 15
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                visible: weekRow.modelData.load !== ""
                                implicitWidth: loadLabel.implicitWidth + 14
                                implicitHeight: loadLabel.implicitHeight + 2
                                radius: height / 2
                                color: view.loadColor[weekRow.modelData.load] || view.s.background_muted
                                Label {
                                    id: loadLabel
                                    anchors.centerIn: parent
                                    text: weekRow.modelData.load
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: weekRow.modelData.load === "h" || weekRow.modelData.load === "m" ? "white" : view.s.text_default
                                }
                            }
                            // LG, WK, HWK of the ITP, and the RTK's
                            // countdown to the main competition
                            Label {
                                objectName: "weekPosition"
                                Layout.alignment: Qt.AlignHCenter
                                visible: text !== ""
                                text: weekRow.modelData.position || ""
                                font.bold: true
                                font.pixelSize: 11
                            }
                            Label {
                                objectName: "weekCountdown"
                                Layout.alignment: Qt.AlignHCenter
                                visible: weekRow.modelData.countdown > 0
                                text: "Tr.-Wo. " + weekRow.modelData.countdown
                                font.pixelSize: 10
                                color: view.s.text_muted
                            }
                        }
                    }

                    // Reps planned / done, with a bar of how much is done
                    Rectangle {
                        visible: !view.allAthletes
                        Layout.preferredWidth: 92
                        Layout.fillHeight: true
                        radius: 4
                        color: view.s.cell_default
                        border.color: view.s.cell_border
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 8
                            spacing: 3
                            Label {
                                text: (weekRow.modelData.whPlan || "–") + " / " + (weekRow.modelData.whActual || "–")
                                font.pixelSize: 12
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 5
                                radius: 2.5
                                color: view.s.background_muted
                                Rectangle {
                                    height: parent.height
                                    radius: 2.5
                                    width: weekRow.modelData.whPlan > 0
                                           ? parent.width * Math.min(1, weekRow.modelData.whActual / weekRow.modelData.whPlan) : 0
                                    color: "#5b6b7f"
                                }
                            }
                        }
                    }

                    Repeater {
                        model: weekRow.modelData.days
                        Rectangle {
                            id: dayCell
                            required property var modelData
                            required property int index
                            objectName: "monthDay" + modelData.date
                            readonly property bool lowered: weekRow.modelData.load === "g"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            radius: 4
                            clip: true
                            color: !modelData.inMonth ? view.s.background_muted
                                   : lowered ? Qt.tint(view.s.cell_default, "#14708aa8") : view.s.cell_default
                            border.color: modelData.today ? view.s.primary_default
                                          : dayHover.hovered ? view.s.stroke_focus : view.s.cell_border
                            border.width: modelData.today || dayHover.hovered ? 2 : 1

                            HoverHandler { id: dayHover }
                            // A double click enters a competition on this day;
                            // a competition's own area lies above it
                            MouseArea {
                                anchors.fill: parent
                                onDoubleClicked: view.competitionRequested(null, dayCell.modelData.date)
                            }

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 5
                                spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: dayCell.modelData.day
                                        font.bold: true
                                        color: dayCell.modelData.inMonth ? view.s.text_default : view.s.text_muted
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        visible: dayCell.modelData.today
                                        text: "heute"
                                        font.pixelSize: 10
                                        color: view.s.text_muted
                                    }
                                }
                                Repeater {
                                    model: dayCell.modelData.sessions
                                    ColumnLayout {
                                        id: sessionItem
                                        required property var modelData
                                        objectName: "session" + modelData.number
                                        spacing: 1
                                        readonly property string text: sessionLabel.text
                                    Label {
                                        id: sessionLabel
                                        readonly property var modelData: sessionItem.modelData
                                        font.pixelSize: 11
                                        // ● with Ist after a Plan, ◆ Ist without one, ○ planned,
                                        // "offen" planned and past without Ist
                                        text: (modelData.state === "done" ? "● " : modelData.state === "free" ? "◆ "
                                               : modelData.state === "open" ? "◌ offen " : "○ ")
                                              + (modelData.wh > 0 ? modelData.wh + " Wh" : modelData.number + ". TE")
                                        color: modelData.state === "open" ? view.s.danger_default
                                               : modelData.state === "planned" ? view.s.text_muted : view.s.text_default
                                    }
                                    // Its reps by complex, in the complexes' colours
                                    Row {
                                        objectName: "groupBar"
                                        readonly property int total: (sessionItem.modelData.groups || []).reduce((a, b) => a + b, 0)
                                        visible: total > 0
                                        Layout.preferredWidth: 60
                                        height: 3
                                        opacity: sessionItem.modelData.state === "planned" || sessionItem.modelData.state === "open" ? 0.45 : 1
                                        Repeater {
                                            model: sessionItem.modelData.groups || []
                                            Rectangle {
                                                required property int modelData
                                                required property int index
                                                width: parent.total > 0 ? 60 * modelData / parent.total : 0
                                                height: 3
                                                color: Theme.groupColor(index + 1)
                                            }
                                        }
                                    }
                                    }
                                }
                                // Lehrgänge (blue, as a band over their days) and
                                // Diagnostik (violet)
                                Repeater {
                                    model: (dayCell.modelData.events || []).filter(e => view.shown(e))
                                    Rectangle {
                                        id: eventChip
                                        required property var modelData
                                        readonly property bool diagnostik: modelData.kind === 2
                                        objectName: "event"
                                        Layout.fillWidth: true
                                        implicitHeight: eventLabel.implicitHeight + 4
                                        radius: 4
                                        color: diagnostik ? "#ede9fe" : "#dbeafe"
                                        HoverHandler { id: eventHover; cursorShape: Qt.PointingHandCursor }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: view.eventRequested(eventChip.modelData.id)
                                            onDoubleClicked: {}
                                        }
                                        ToolTip.visible: eventHover.hovered
                                        ToolTip.text: eventChip.modelData.kindName + ": " + eventChip.modelData.name
                                                      + "\n" + eventChip.modelData.dateText
                                                      + (eventChip.modelData.place ? ", " + eventChip.modelData.place : "")
                                                      + (view.allAthletes ? "\n" + eventChip.modelData.athlete : "")
                                                      + "\nKlick: ändern"
                                        Label {
                                            id: eventLabel
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 4
                                            anchors.rightMargin: 4
                                            elide: Text.ElideRight
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: eventChip.diagnostik ? "#6d28d9" : "#1d4ed8"
                                            // The name on the first day and at the start of a week
                                            text: eventChip.modelData.firstDay || dayCell.index % 7 === 0
                                                  ? (eventChip.diagnostik ? "◇ " : "▭ ") + eventChip.modelData.name
                                                    + (view.allAthletes ? " · " + eventChip.modelData.athlete : "")
                                                  : " "
                                        }
                                    }
                                }
                                Repeater {
                                    model: view.showCompetitions ? dayCell.modelData.competitions : []
                                    Rectangle {
                                        id: chip
                                        required property var modelData
                                        objectName: "competition"
                                        Layout.fillWidth: true
                                        implicitHeight: chipLabel.implicitHeight + 4
                                        radius: 4
                                        color: "#fde7d7"
                                        HoverHandler { id: compHover; cursorShape: Qt.PointingHandCursor }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: view.competitionRequested(chip.modelData, "")
                                            // Not a new one on the day below
                                            onDoubleClicked: {}
                                        }
                                        ToolTip.visible: compHover.hovered
                                        ToolTip.text: chip.modelData.name
                                                      + (chip.modelData.place ? ", " + chip.modelData.place : "")
                                                      + (view.allAthletes ? "\n" + chip.modelData.athlete : "")
                                                      + "\nKlick: ändern"
                                        Label {
                                            id: chipLabel
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 4
                                            anchors.rightMargin: 4
                                            elide: Text.ElideRight
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "#c2410c"
                                            text: "★ " + chip.modelData.name
                                                  + (view.allAthletes ? " · " + chip.modelData.athlete : "")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // What the marks mean
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Label {
                    visible: !view.allAthletes
                    font.pixelSize: 11
                    color: view.s.text_muted
                    text: "● Ist nach Plan   ◆ Ist ohne Plan   ○ geplant   ◌ offen (geplant, ohne Ist)   h / m / g: Belastung aus dem ITP"
                }
                Item { Layout.fillWidth: true }
                Label {
                    font.pixelSize: 11
                    color: view.s.text_muted
                    text: "Klick auf die KW: Woche öffnen · Doppelklick auf einen Tag: Wettkampf"
                }
            }
        }

        // The coming competitions
        Frame {
            Layout.preferredWidth: 270
            Layout.fillHeight: true
            padding: 10
            background: Rectangle {
                color: view.s.background_elevated
                border.color: view.s.stroke_subtle
                radius: 4
            }
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                Label { text: "Termine"; font.bold: true; font.pixelSize: 14 }
                // Which kinds of dates the calendar and this list show
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    CheckBox { objectName: "showCompetitions"; text: "Wettkämpfe"; checked: view.showCompetitions; onToggled: view.showCompetitions = checked }
                    CheckBox { objectName: "showLehrgang"; text: "Lehrgänge"; checked: view.showLehrgang; onToggled: view.showLehrgang = checked }
                    CheckBox { objectName: "showDiagnostik"; text: "Diagnostik"; checked: view.showDiagnostik; onToggled: view.showDiagnostik = checked }
                }
                Repeater {
                    model: (view.monthData.upcoming || []).filter(t => view.shown(t))
                    Frame {
                        id: termin
                        required property var modelData
                        objectName: "termin"
                        Layout.fillWidth: true
                        padding: 7
                        background: Rectangle {
                            color: view.s.cell_default
                            border.color: terminHover.hovered ? view.s.stroke_focus : view.s.stroke_subtle
                            radius: 4
                        }
                        HoverHandler { id: terminHover; cursorShape: Qt.PointingHandCursor }
                        // A handler, not a MouseArea: the frame's children go into
                        // its layout, where anchors are not allowed
                        TapHandler {
                            onTapped: termin.modelData.isEvent ? view.eventRequested(termin.modelData.id)
                                                               : view.competitionRequested(termin.modelData, "")
                        }
                        contentItem: ColumnLayout {
                            spacing: 1
                            Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.bold: true
                                text: termin.modelData.dateText + " · " + termin.modelData.name
                                color: termin.modelData.isEvent ? (termin.modelData.kind === 2 ? "#6d28d9" : "#1d4ed8")
                                                                : view.s.text_default
                            }
                            Label {
                                objectName: "terminNorm"
                                Layout.fillWidth: true
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                font.pixelSize: 11
                                text: termin.modelData.norm || ""
                            }
                            Label {
                                objectName: "terminWarning"
                                Layout.fillWidth: true
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                font.pixelSize: 11
                                color: view.s.danger_default
                                text: termin.modelData.warning || ""
                            }
                            Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pixelSize: 11
                                color: view.s.text_muted
                                text: [termin.modelData.isEvent ? termin.modelData.kindName : "",
                                       termin.modelData.place, view.allAthletes ? termin.modelData.athlete : "",
                                       termin.modelData.days < 0 ? "läuft" : termin.modelData.days === 0 ? "heute"
                                       : termin.modelData.days === 1 ? "morgen"
                                       : "in " + termin.modelData.days + " Tagen"].filter(t => t).join(" · ")
                            }
                        }
                    }
                }
                Label {
                    visible: (view.monthData.upcoming || []).length === 0
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: view.s.text_muted
                    text: "Keine Wettkämpfe in Sicht. Mit „+ Wettkampf“ oder einem Doppelklick auf einen Tag eintragen."
                }
                Item { Layout.fillHeight: true }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: view.s.text_muted
                    text: view.allAthletes ? "Die Termine aller Sportler, wie ein Wandkalender."
                                           : "„Alle Sportler“ zeigt die Termine aller Sportler."
                }
            }
        }
    }
}
