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

    function reload() {
        monthData = month !== "" && (allAthletes || athleteId !== "") ? Store.month(athleteId, month, allAthletes) : {}
    }
    onAthleteIdChanged: reload()
    onMonthChanged: reload()
    onAllAthletesChanged: reload()
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

    RowLayout {
        anchors.fill: parent
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            // Column heads
            RowLayout {
                Layout.fillWidth: true
                spacing: 3
                Label { Layout.preferredWidth: 10 }
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

                    // The MAZ's phase down the left edge
                    Rectangle {
                        Layout.preferredWidth: 10
                        Layout.fillHeight: true
                        radius: 3
                        color: weekRow.modelData.phase === "Leistungsausprägung" ? "#4d6680"
                               : weekRow.modelData.phase === "Aufbauphase" ? "#8aa1b8"
                               : weekRow.modelData.phase !== "" ? "#c3cfdb" : "transparent"
                        HoverHandler { id: phaseHover }
                        ToolTip.visible: phaseHover.hovered && weekRow.modelData.phase !== ""
                        ToolTip.text: weekRow.modelData.phase
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
                                    Label {
                                        required property var modelData
                                        objectName: "session" + modelData.number
                                        font.pixelSize: 11
                                        // ● with Ist after a Plan, ◆ Ist without one, ○ planned,
                                        // "offen" planned and past without Ist
                                        text: (modelData.state === "done" ? "● " : modelData.state === "free" ? "◆ "
                                               : modelData.state === "open" ? "◌ offen " : "○ ")
                                              + (modelData.wh > 0 ? modelData.wh + " Wh" : modelData.number + ". TE")
                                        color: modelData.state === "open" ? view.s.danger_default
                                               : modelData.state === "planned" ? view.s.text_muted : view.s.text_default
                                    }
                                }
                                Repeater {
                                    model: dayCell.modelData.competitions
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
                Repeater {
                    model: view.monthData.upcoming || []
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
                        MouseArea {
                            anchors.fill: parent
                            onClicked: view.competitionRequested(termin.modelData, "")
                        }
                        contentItem: ColumnLayout {
                            spacing: 1
                            Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.bold: true
                                text: termin.modelData.dateText + " · " + termin.modelData.name
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
                                text: [termin.modelData.place, view.allAthletes ? termin.modelData.athlete : "",
                                       termin.modelData.days === 0 ? "heute" : termin.modelData.days === 1 ? "morgen"
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
                    text: view.allAthletes ? "Die Wettkämpfe aller Sportler, wie ein Wandkalender."
                                           : "„Alle Sportler“ zeigt die Wettkämpfe aller Sportler."
                }
            }
        }
    }
}
