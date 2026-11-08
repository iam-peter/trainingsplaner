import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

// One training session in the week grid. Click to edit.
Rectangle {
    id: cell

    property var session: null
    property int sessionNumber: 1
    signal clicked()

    readonly property bool filled: session !== null

    radius: 10
    color: mouse.containsMouse ? "#fff0b0" : "#fff6cf"
    border.color: mouse.containsMouse ? "#b08a00" : "#8c7a45"
    border.width: mouse.containsMouse ? 2 : 1
    clip: true

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.clicked()
    }

    Label {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 5
        text: cell.sessionNumber + ". TE"
        font.pixelSize: 10
        color: "#9a8a5a"
    }

    IconImage {
        anchors.centerIn: parent
        visible: !cell.filled && mouse.containsMouse
        source: "qrc:/qt/qml/Trainingsplaner/icons/plus.svg"
        sourceSize: Qt.size(28, 28)
        color: "#b08a00"
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        anchors.topMargin: 16
        spacing: 1
        visible: cell.filled

        Repeater {
            model: cell.filled ? cell.session.entries : []
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                Label {
                    visible: modelData.kind !== 2
                    Layout.preferredWidth: 20
                    horizontalAlignment: Text.AlignRight
                    text: modelData.exercise
                    font.bold: true
                    font.pixelSize: 13
                    color: "black"
                }
                Label {
                    Layout.fillWidth: true
                    text: modelData.line
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    font.italic: modelData.kind === 2
                    color: "black"
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
        color: "black"
    }

    ToolTip.visible: mouse.containsMouse && filled && session.note !== ""
    ToolTip.text: filled ? session.note : ""
    ToolTip.delay: 600
}
