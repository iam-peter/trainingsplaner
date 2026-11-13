import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// One use of the exercise in the week: day, session and weight steps.
Frame {
    id: row

    property var source: ({})   // read once
    property bool actual: false
    property bool canPaste: false
    property int day: 1
    property int number: 1
    // How much the athlete usually adds per step (Store.usualJump)
    property real jump: 5
    // Earlier lines of the exercise (Store.recentSteps)
    property var suggestions: []
    readonly property var rowStats: stepsEditor.stats
    // Under the pointer, so the week can mark its session
    readonly property bool pointerOver: rowHover.hovered

    signal changed()
    signal removeRequested()
    signal copyRequested(var steps)
    signal pasteRequested()

    function setSteps(list) {
        stepsEditor.setSteps(list)
    }

    function value() {
        return {
            origDay: source.origDay || 0,
            origNumber: source.origNumber || 0,
            origIndex: source.origIndex === undefined ? -1 : source.origIndex,
            day: day,
            number: number,
            steps: stepsEditor.value()
        }
    }

    function focusFirst() {
        stepsEditor.focusFirst()
    }

    Component.onCompleted: {
        day = source.day || 1
        number = source.number || 1
    }

    // Two rows, to fit beside the week: the session (day, TE) with the
    // figures and buttons, then the weight steps
    padding: 10
    background: Rectangle {
        color: Styles.TokenInterface.semantics.background_default
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        radius: Styles.Primitives.radius.r4
    }

    HoverHandler { id: rowHover }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ComboBox {
                objectName: "dayBox"
                implicitWidth: 130
                model: [1, 2, 3, 4, 5, 6, 7].map(d => Store.dayName(d))
                currentIndex: row.day - 1
                onActivated: (index) => {
                    row.day = index + 1
                    row.changed()
                }
            }
            ComboBox {
                objectName: "sessionBox"
                implicitWidth: 90
                model: ["1. TE", "2. TE", "3. TE"]
                currentIndex: row.number - 1
                onActivated: (index) => {
                    row.number = index + 1
                    row.changed()
                }
            }
            Label {
                objectName: "figures"
                Layout.fillWidth: true
                Layout.leftMargin: 6
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: "WH " + (row.rowStats.wh || 0) + " · MHG " + (row.rowStats.mhg || 0)
                      + " · BW " + (row.rowStats.bw || 0) + (row.rowStats.repsSets ? " " + row.rowStats.repsSets : "")
                font.bold: true
                font.pixelSize: 12
            }
            // Out of the Tab order, which goes from the session to its weights
            RowLayout {
                Layout.rightMargin: -6
                spacing: 0
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "clipboard-copy"
                    toolTip: "Laststufen kopieren"
                    onClicked: row.copyRequested(stepsEditor.value())
                }
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "clipboard-paste"
                    toolTip: "Kopierte Laststufen einfügen"
                    enabled: row.canPaste
                    onClicked: row.pasteRequested()
                }
                IconToolButton {
                    activeFocusOnTab: false
                    iconName: "trash-2"
                    toolTip: "Aus dieser Einheit entfernen"
                    onClicked: row.removeRequested()
                }
            }
        }

        StepsEditor {
            id: stepsEditor
            Layout.fillWidth: true
            initialSteps: row.source.steps || []
            actual: row.actual
            jump: row.jump
            suggestions: row.suggestions
            onChanged: row.changed()
        }
    }
}
