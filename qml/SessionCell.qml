import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts
import Trainingsplaner
import TrainingsplanerStyle as Styles

// One training session in the week grid. Click or Enter to edit, Delete
// to remove, arrow keys to move to the neighbouring session, right click
// or the menu key for more.
Rectangle {
    id: cell

    property var session: null
    property int sessionNumber: 1
    property bool today: false
    signal clicked()
    signal deleteRequested()
    signal moveRequested(int days, int sessions)
    signal copyRequested()
    signal pasteRequested()
    // exercise: the weight exercise under the pointer, 0 for none
    signal menuRequested(int exercise, real x, real y)
    // A weight exercise line was clicked: edit that exercise for the week
    signal exerciseClicked(int exercise)

    readonly property bool filled: session !== null

    Styles.StyleCascade {
        id: _cellStyle
        base: [CellStyle.base]
        overrides: [cell.today ? CellStyle.today : null, cell.activeFocus ? CellStyle.focus : null]
        state: hover.hovered ? Styles.StyleState.Hover : Styles.StyleState.Idle
    }
    Styles.StyleCascade {
        id: _numberStyle
        parentCascade: _cellStyle
        part: Styles.StylePart.Label
    }
    Styles.StyleCascade {
        id: _plusStyle
        parentCascade: _cellStyle
        part: Styles.StylePart.Icon
    }
    Styles.StyleCascade {
        id: _lineStyle
        parentCascade: _cellStyle
        part: Styles.StylePart.Indicator
    }

    radius: _cellStyle.radius.value
    color: _cellStyle.background
    border.color: _cellStyle.border.color
    border.width: _cellStyle.border.width
    clip: true

    // The whole cell, lines included: the cell's MouseArea loses the hover
    // to a line's MouseArea, which made the background flicker between lines
    HoverHandler {
        id: hover
    }

    activeFocusOnTab: true
    Keys.onReturnPressed: cell.clicked()
    Keys.onEnterPressed: cell.clicked()
    Keys.onSpacePressed: cell.clicked()
    Keys.onDeletePressed: if (cell.filled) cell.deleteRequested()
    Keys.onPressed: (event) => {
        if (event.matches(StandardKey.Copy))
            cell.copyRequested()
        else if (event.matches(StandardKey.Paste))
            cell.pasteRequested()
        else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers === Qt.ShiftModifier))
            cell.menuRequested(0, 16, 16)
        else
            return
        event.accepted = true
    }
    Keys.onLeftPressed: (event) => { if (event.modifiers === Qt.NoModifier) cell.moveRequested(-1, 0); else event.accepted = false }
    Keys.onRightPressed: (event) => { if (event.modifiers === Qt.NoModifier) cell.moveRequested(1, 0); else event.accepted = false }
    Keys.onUpPressed: (event) => { if (event.modifiers === Qt.NoModifier) cell.moveRequested(0, -1); else event.accepted = false }
    Keys.onDownPressed: (event) => { if (event.modifiers === Qt.NoModifier) cell.moveRequested(0, 1); else event.accepted = false }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouseEvent) => {
            cell.forceActiveFocus()
            if (mouseEvent.button === Qt.RightButton)
                cell.menuRequested(0, mouseEvent.x, mouseEvent.y)
            else
                cell.clicked()
        }
    }

    Label {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        text: cell.sessionNumber + ". TE"
        font.pixelSize: 10
        color: _numberStyle.text.color
    }

    IconImage {
        anchors.centerIn: parent
        visible: !cell.filled && hover.hovered
        source: Theme.icon("plus")
        sourceSize: Qt.size(28, 28)
        color: _plusStyle.icon.color
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        anchors.topMargin: 16
        // No gap between the lines, so the pointer never falls between two
        spacing: 0
        visible: cell.filled

        Repeater {
            model: cell.filled ? cell.session.entries : []
            Item {
                id: line
                required property var modelData
                required property int index
                objectName: "line" + index
                readonly property bool weights: modelData.kind === 0 && modelData.exercise > 0
                Layout.fillWidth: true
                implicitHeight: lineRow.implicitHeight + 3

                // Outline on hover, like the selected line in the old program
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: height / 2
                    color: "transparent"
                    border.color: _lineStyle.border.color
                    border.width: _lineStyle.border.width
                    visible: line.weights && lineMouse.containsMouse
                }
                MouseArea {
                    id: lineMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: line.weights ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    // Other lines pass clicks on to the cell (open the session)
                    onClicked: (mouseEvent) => {
                        cell.forceActiveFocus()
                        if (mouseEvent.button === Qt.RightButton) {
                            const p = mapToItem(cell, mouseEvent.x, mouseEvent.y)
                            cell.menuRequested(line.weights ? line.modelData.exercise : 0, p.x, p.y)
                        } else if (line.weights)
                            cell.exerciseClicked(line.modelData.exercise)
                        else
                            cell.clicked()
                    }
                    ToolTip.visible: containsMouse && line.tip !== ""
                    ToolTip.text: line.tip
                    ToolTip.delay: 500
                }
                // "8 Umgruppieren breit – WH 15 · MHG 13 · BW 15 (3/2)"
                readonly property string tip: {
                    const m = modelData
                    if (m.kind === 2)
                        return ""
                    let t = m.exercise + "  " + m.name
                    if (m.kind === 0 && m.stats && !m.stats.empty)
                        t += "\nWH " + m.stats.wh + " · MHG " + m.stats.mhg + " · BW " + m.stats.bw
                             + (m.stats.repsSets ? " (" + m.stats.repsSets + ")" : "")
                             + "\nKlicken: Übung für die ganze Woche bearbeiten"
                    else if (m.text)
                        t += ": " + m.text
                    return t
                }

                RowLayout {
                id: lineRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Label {
                    visible: line.modelData.kind !== 2
                    Layout.preferredWidth: 20
                    horizontalAlignment: Text.AlignRight
                    text: line.modelData.exercise
                    font.bold: true
                    font.pixelSize: 13
                    color: _cellStyle.text.color
                }
                Label {
                    Layout.fillWidth: true
                    text: line.modelData.line
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    font.italic: line.modelData.kind === 2
                    color: _cellStyle.text.color
                }
                }
            }
        }
    }

    Label {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 4
        visible: cell.filled && cell.session.from !== ""
        text: cell.filled ? cell.session.from + " Uhr" : ""
        font.pixelSize: 11
        color: _cellStyle.text.color
    }

    ToolTip.visible: mouse.containsMouse && filled && session.note !== ""
    ToolTip.text: filled ? session.note : ""
    ToolTip.delay: 600
}
