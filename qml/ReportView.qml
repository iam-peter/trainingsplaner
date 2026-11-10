import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

// An analysis report (HTML) with printing and PDF export. It shows at
// once and follows its settings and the data: request is what it is built
// from (one binding over the settings), build(request) makes the HTML.
ColumnLayout {
    id: view

    property var request: null
    property var build: null
    // false while a setting is half typed (a week): the report stays
    property bool ready: true
    // What shows without a report (no athlete, no MAZ)
    property string emptyText: "Keine Daten."
    property string html
    property string title

    property bool stale: true
    property double builtAt: 0
    function rebuild() {
        later.stop()
        stale = false
        const h = request && build ? build(request) : ""
        if (h !== html)
            html = h
        builtAt = Date.now()
    }
    // Hidden or half typed, it only notes the change. A single change (a
    // click) rebuilds it at once; one coming quickly after another (typing,
    // a spin box arrow held) waits until they pause. Built while the tabs
    // are still being set up, all briefly visible: a hidden one waits.
    function rebuildIfShown() {
        if (visible && ready && stale)
            rebuild()
    }
    function changed() {
        stale = true
        if (!visible || !ready)
            return
        if (Date.now() - builtAt > 300)
            Qt.callLater(rebuildIfShown)
        else
            later.restart()
    }
    onRequestChanged: changed()
    onReadyChanged: if (ready) changed()
    onVisibleChanged: rebuildIfShown()
    Connections {
        target: Store
        function onDataChanged() { view.changed() }
    }
    Connections {
        target: Plan
        function onChanged() { view.changed() }
    }
    Timer {
        id: later
        interval: 150
        onTriggered: view.rebuildIfShown()
    }

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
            text: view.emptyText
            color: Styles.TokenInterface.semantics.text_muted
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
