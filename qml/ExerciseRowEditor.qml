import QtQuick
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
    readonly property var rowStats: stepsEditor.stats

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

    padding: 6
    background: Rectangle {
        color: palette.window
        border.color: palette.mid
        radius: Theme.radius(4)
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 4
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
                implicitWidth: 130
                model: ["1. TE", "2. TE", "3. TE"]
                currentIndex: row.number - 1
                onActivated: (index) => {
                    row.number = index + 1
                    row.changed()
                }
            }
        }

        StepsEditor {
            id: stepsEditor
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            initialSteps: row.source.steps || []
            actual: row.actual
            onChanged: row.changed()
        }

        // Figures of this session
        GridLayout {
            Layout.alignment: Qt.AlignTop
            columns: 2
            columnSpacing: 16
            rowSpacing: 4
            Label {
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: row.rowStats.mhg || 0
            }
            Label {
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: row.rowStats.bw || 0
            }
            Label {
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: row.rowStats.wh || 0
            }
            Label {
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                text: row.rowStats.repsSets || "–"
            }
        }

        IconToolButton {
            Layout.alignment: Qt.AlignTop
            iconName: "clipboard-copy"
            toolTip: "Laststufen kopieren"
            onClicked: row.copyRequested(stepsEditor.value())
        }
        IconToolButton {
            Layout.alignment: Qt.AlignTop
            iconName: "clipboard-paste"
            toolTip: "Kopierte Laststufen einfügen"
            enabled: row.canPaste
            onClicked: row.pasteRequested()
        }
        IconToolButton {
            Layout.alignment: Qt.AlignTop
            iconName: "trash-2"
            toolTip: "Aus dieser Einheit entfernen"
            onClicked: row.removeRequested()
        }
    }
}
