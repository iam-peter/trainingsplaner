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

    spacing: 6

    RowLayout {
        Label { text: view.title; font.bold: true; Layout.fillWidth: true }
        IconButton {
            iconName: "printer"
            text: "Drucken…"
            enabled: view.html !== ""
            onClicked: Analysis.printHtml(view.html, view.title)
        }
        IconButton {
            iconName: "file-down"
            text: "PDF…"
            enabled: view.html !== ""
            onClicked: pdfDialog.open()
        }
    }

    Frame {
        Layout.fillWidth: true
        Layout.fillHeight: true
        padding: 0
        background: Rectangle { color: palette.base; border.color: palette.mid }
        ScrollView {
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
