import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

// An analysis report (HTML) with printing and PDF export.
ColumnLayout {
    id: view

    property string html
    property string title

    spacing: 8

    RowLayout {
        spacing: 8
        // On the line of the first heading beside it (Sportler, MAZ), not
        // centred on the buttons
        Label { text: view.title; font.bold: true; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop }
        IconButton {
            iconName: "printer"
            text: "Drucken"
            enabled: view.html !== ""
            onClicked: Analysis.printHtml(view.html, view.title)
        }
        IconButton {
            iconName: "file-down"
            text: "PDF"
            enabled: view.html !== ""
            onClicked: pdfDialog.open()
        }
    }

    // Framed like the program's other panels
    Panel {
        Layout.fillWidth: true
        Layout.fillHeight: true
        filled: true
        padding: 1
        ScrollView {
            // No overshoot at the ends
            Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
            anchors.fill: parent
            TextArea {
                objectName: "reportText"
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.RichText
                text: view.html
                wrapMode: TextEdit.NoWrap
                padding: 12
                background: null
            }
        }
        Label {
            anchors.centerIn: parent
            visible: view.html === ""
            text: "Einstellungen wählen und „Tabelle“ drücken."
            color: palette.placeholderText
        }
    }

    FileDialog {
        id: pdfDialog
        title: "Als PDF speichern"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "pdf"
        nameFilters: ["PDF (*.pdf)"]
        onAccepted: Analysis.saveHtmlPdf(view.html, view.title, selectedFile)
    }
}
