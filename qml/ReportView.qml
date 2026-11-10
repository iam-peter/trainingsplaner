import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

// An analysis report (Analysis.individual() and the like) with printing
// and PDF export. It shows at once and follows its settings and the data:
// request is what it is built from (one binding over the settings),
// build(request) makes the report. The tables look like the program's
// first reports: thin lines, a grey header row, the first column left.
ColumnLayout {
    id: view

    property var request: null
    property var build: null
    // false while a setting is half typed (a week): the report stays
    property bool ready: true
    // What shows without a report (no athlete, no MAZ)
    property string emptyText: "Keine Daten."
    property var report: ({})
    readonly property bool hasReport: !reportModel.empty
    property string title

    property bool stale: true
    property double builtAt: 0
    function rebuild() {
        later.stop()
        stale = false
        // An unchanged report leaves the table as it is (the model compares)
        report = request && build ? build(request) : ({})
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
            enabled: view.hasReport
            onClicked: Analysis.printReport(view.report)
        }
        IconButton {
            iconName: "file-down"
            text: "PDF"
            enabled: view.hasReport
            onClicked: pdfDialog.open()
        }
    }

    ReportModel {
        id: reportModel
        report: view.report
        font: sample.font
        onLayoutDone: table.forceLayout()
    }
    // The font of the cells, for the model to measure them by, and the
    // larger ones of the title and the headings (13 and 10.5 pt beside 9 pt
    // on paper)
    Text { id: sample; visible: false }
    function scaled(factor, bold) {
        const f = sample.font
        return f.pixelSize > 0 ? Qt.font({ family: f.family, pixelSize: Math.round(f.pixelSize * factor), bold: bold })
                               : Qt.font({ family: f.family, pointSize: f.pointSize * factor, bold: bold })
    }
    readonly property font titleFont: scaled(1.45, true)
    readonly property font headingFont: scaled(1.17, true)
    readonly property font boldFont: scaled(1, true)

    // Framed like the program's other panels
    Panel {
        Layout.fillWidth: true
        Layout.fillHeight: true
        filled: true
        padding: 1
        TableView {
            id: table
            objectName: "reportTable"
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: reportModel
            leftMargin: 12
            topMargin: 12
            // A fixed room for the bars: room that follows a bar would change
            // whether it shows (a loop), as in the ITP grid
            rightMargin: 12 + vbar.width + 4
            bottomMargin: 12 + hbar.height + 4
            // Every size is known: nothing left to estimate
            contentWidth: reportModel.totalWidth
            contentHeight: reportModel.totalHeight
            columnWidthProvider: (column) => reportModel.columnWidth(column)
            rowHeightProvider: (row) => reportModel.rowHeight(row)
            ScrollBar.horizontal: AppScrollBar { id: hbar }
            ScrollBar.vertical: AppScrollBar { id: vbar }

            delegate: Item {
                id: cell
                required property string display
                required property int kind
                required property bool bold
                required property bool muted
                required property bool alignLeft
                readonly property bool inTable: kind === ReportModel.Header || kind === ReportModel.Cell

                // A pixel past the cell: the lines of neighbouring cells
                // fall on each other, as in a table with collapsed borders
                Rectangle {
                    visible: cell.inTable
                    width: parent.width + 1
                    height: parent.height + 1
                    color: cell.kind === ReportModel.Header ? Styles.TokenInterface.semantics.background_muted
                                                            : Styles.TokenInterface.semantics.background_elevated
                    border.width: 1
                    border.color: Styles.TokenInterface.semantics.text_muted
                }
                // Headings and notes reach over the columns beside them
                Text {
                    visible: cell.display !== ""
                    x: cell.inTable ? reportModel.padding : 0
                    // In a table as wide as its cell; elsewhere as its text
                    Binding on width {
                        when: cell.inTable
                        value: cell.width - 2 * reportModel.padding
                    }
                    height: parent.height
                    text: cell.display
                    textFormat: Text.PlainText
                    font: cell.kind === ReportModel.Title ? view.titleFont
                          : cell.kind === ReportModel.Heading ? view.headingFont
                          : cell.bold ? view.boldFont : sample.font
                    horizontalAlignment: cell.inTable && !cell.alignLeft ? Text.AlignRight : Text.AlignLeft
                    verticalAlignment: cell.kind === ReportModel.Title || cell.kind === ReportModel.Heading
                                       ? Text.AlignBottom
                                       : cell.kind === ReportModel.Note ? Text.AlignTop : Text.AlignVCenter
                    topPadding: cell.kind === ReportModel.Note ? 2 : 0
                    bottomPadding: cell.kind === ReportModel.Title || cell.kind === ReportModel.Heading ? 4 : 0
                    color: cell.muted ? Styles.TokenInterface.semantics.text_muted
                                      : Styles.TokenInterface.semantics.text_default
                }
            }
        }
        Label {
            anchors.centerIn: parent
            visible: !view.hasReport
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
        onAccepted: Analysis.saveReportPdf(view.report, selectedFile)
    }
}
