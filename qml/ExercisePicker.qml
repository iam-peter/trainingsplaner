import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Grid of exercise numbers, one row per group. The title names the
// exercise under the pointer, else the chosen one, always with its number.
Popup {
    id: picker

    // true: general exercises entered as text (AMKT); false: weight exercises
    property bool textExercises: false
    property int current: 0
    // The exercise under the pointer, 0 for none
    property int hovered: 0
    readonly property int shown: hovered > 0 ? hovered : current

    signal picked(int id)

    // The buttons are made the first time the picker opens: every line of
    // a session has its own picker, and most are never opened
    property bool built: false

    readonly property var rows: {
        if (!built)
            return []
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
    focus: true
    onAboutToShow: built = true
    onOpened: hovered = 0

    contentItem: ColumnLayout {
        spacing: 4

        Label {
            objectName: "pickerTitle"
            Layout.fillWidth: true
            Layout.preferredWidth: 300
            horizontalAlignment: Text.AlignHCenter
            text: picker.shown > 0 ? picker.shown + "  " + Store.exerciseName(picker.shown) : "Übung wählen"
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
                    color: Styles.TokenInterface.semantics.text_muted
                    font.pixelSize: 11
                }
                Repeater {
                    model: modelData.items
                    Button {
                        required property var modelData
                        implicitWidth: 34
                        implicitHeight: 28
                        // Small square buttons: no style padding, so two
                        // digits fit
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        text: modelData.id
                        highlighted: modelData.id === picker.current
                        hoverEnabled: true
                        objectName: "exercise" + modelData.id
                        onHoveredChanged: {
                            if (hovered)
                                picker.hovered = modelData.id
                            else if (picker.hovered === modelData.id)
                                picker.hovered = 0
                        }
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
