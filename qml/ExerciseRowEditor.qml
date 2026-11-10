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

    // The same 12 px on every side: the icon buttons on the right are
    // pulled out by the free space around their icons (8 px), so the icons
    // end 12 px from the border like the fields on the left
    padding: 12
    background: Rectangle {
        color: Styles.TokenInterface.semantics.background_default
        border.color: Styles.TokenInterface.semantics.stroke_subtle
        radius: Styles.Primitives.radius.r4
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

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
            // Pulled out by the free space around its icon, see padding
            Layout.rightMargin: -8
            iconName: "trash-2"
            toolTip: "Aus dieser Einheit entfernen"
            onClicked: row.removeRequested()
        }
    }
}
