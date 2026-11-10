import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The form beside a list (Sportler, Wettkämpfe): a title, the fields as a
// grid of label and field, and the buttons below. The fields scroll when
// the window is low; the buttons stay in view.
Panel {
    id: panel

    property string title
    // The rows of the form: a label, then its field (or a row of fields)
    default property alias fields: form.data
    property alias buttons: buttonRow.data

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: panel.title
            font.bold: true
            font.pixelSize: 16
        }

        ScrollView {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            GridLayout {
                id: form
                width: scroller.availableWidth
                columns: 2
                columnSpacing: 12
                rowSpacing: 8
            }
        }

        RowLayout {
            id: buttonRow
            spacing: 8
        }
    }
}
