import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Picks a time of day: the 24 hours in a grid, the minutes in quarter
// hours next to them. An hour sets the time at once (with the minutes
// chosen so far, else :00); a minute completes it and closes the picker.
Popup {
    id: picker

    property int hour: -1
    property int minute: -1
    signal picked(int hour, int minute)
    signal cleared()

    readonly property var minutes: [0, 15, 30, 45]

    padding: 8

    function two(n) {
        return (n < 10 ? "0" : "") + n
    }

    // An hour or a minute: the chosen one and the one under the pointer
    // as in the other pickers
    component Cell: Button {
        id: cell
        property bool chosen: false
        implicitWidth: 40
        implicitHeight: 32
        // Small square buttons: no style padding, so two digits fit
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        flat: true
        background: Rectangle {
            color: cell.chosen ? Theme.sh.pickerChosen : cell.hovered ? Theme.sh.pickerHover : "transparent"
            radius: Theme.radius(4)
        }
    }

    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignTop
            ColumnLayout {
                spacing: 4
                Label { text: "Stunde"; font.pixelSize: 11; color: palette.placeholderText }
                GridLayout {
                    objectName: "hours"
                    columns: 4
                    rowSpacing: 4
                    columnSpacing: 4
                    flow: GridLayout.TopToBottom
                    rows: 6
                    Repeater {
                        model: 24
                        Cell {
                            required property int index
                            objectName: "hour" + index
                            text: picker.two(index)
                            chosen: index === picker.hour
                            onClicked: {
                                picker.hour = index
                                picker.picked(index, Math.max(0, picker.minute))
                            }
                        }
                    }
                }
            }
            ToolSeparator { Layout.fillHeight: true }
            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignTop
                Label { text: "Minute"; font.pixelSize: 11; color: palette.placeholderText }
                Repeater {
                    model: picker.minutes
                    Cell {
                        required property int modelData
                        objectName: "minute" + modelData
                        text: ":" + picker.two(modelData)
                        chosen: modelData === picker.minute
                        onClicked: {
                            picker.minute = modelData
                            picker.picked(Math.max(0, picker.hour), modelData)
                            picker.close()
                        }
                    }
                }
            }
        }
        RowLayout {
            spacing: 8
            IconButton {
                objectName: "clearButton"
                iconName: "brush-cleaning"
                text: "Leeren"
                flat: true
                onClicked: {
                    picker.cleared()
                    picker.close()
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Fertig"
                onClicked: picker.close()
            }
        }
    }
}
