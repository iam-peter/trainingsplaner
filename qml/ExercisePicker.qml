import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Grid of exercise numbers, one row per group. Hovering shows the name.
Popup {
    id: picker

    // true: general exercises entered as text (AMKT); false: weight exercises
    property bool textExercises: false
    property int current: 0
    property string hoverName: ""

    signal picked(int id)

    readonly property var rows: {
        const byGroup = {}
        for (const e of Store.catalog) {
            if (e.text !== picker.textExercises)
                continue
            if (!byGroup[e.group])
                byGroup[e.group] = []
            byGroup[e.group].push(e)
        }
        return Object.keys(byGroup).map(g => ({ group: parseInt(g), items: byGroup[g] }))
    }

    padding: 12
    modal: false
    focus: true
    onOpened: hoverName = ""

    contentItem: ColumnLayout {
        spacing: 4

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 300
            horizontalAlignment: Text.AlignHCenter
            text: picker.hoverName !== "" ? picker.hoverName
                  : (picker.current > 0 ? Store.exerciseName(picker.current) : "Übung wählen")
            font.bold: true
        }

        Repeater {
            model: picker.rows
            RowLayout {
                required property var modelData
                spacing: 2
                Label {
                    Layout.preferredWidth: 46
                    text: modelData.group <= 7 ? "K" + modelData.group : "AMKT"
                    color: palette.placeholderText
                    font.pixelSize: 11
                }
                Repeater {
                    model: modelData.items
                    Button {
                        required property var modelData
                        implicitWidth: 34
                        implicitHeight: 28
                        // Small square buttons: no style padding, so two
                        // digits fit in every style
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        text: modelData.id
                        highlighted: modelData.id === picker.current
                        hoverEnabled: true
                        onHoveredChanged: if (hovered) picker.hoverName = modelData.id + "  " + modelData.name
                        onClicked: {
                            picker.picked(modelData.id)
                            picker.close()
                        }
                    }
                }
            }
        }
    }
}
