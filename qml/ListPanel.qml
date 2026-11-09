import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// The list beside a form (Sportler, Wettkämpfe, MAZ): a framed list of
// ListRows up to the border, a text while it is empty, and a button below
// that adds an entry. The rows keep the same gap to the border on every
// side, the button 8 px like the content of the panel beside it.
Panel {
    id: panel

    property alias model: list.model
    property alias delegate: list.delegate
    readonly property alias count: list.count
    // Shown while there are no rows
    property string emptyText
    // The button below; none without a text
    property string addText
    property string addIcon: "plus"

    signal addClicked()

    padding: 1
    filled: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // With the rows' inset, the selection keeps the same gap to the
            // border on every side
            topMargin: Theme.listMargin
            bottomMargin: Theme.listMargin
            ScrollBar.vertical: AppScrollBar {}

            Label {
                anchors.centerIn: parent
                visible: list.count === 0
                text: panel.emptyText
                color: Styles.TokenInterface.semantics.text_muted
            }
        }

        IconButton {
            objectName: "addButton"
            visible: panel.addText !== ""
            Layout.fillWidth: true
            Layout.margins: 8
            iconName: panel.addIcon
            text: panel.addText
            onClicked: panel.addClicked()
        }
    }
}
