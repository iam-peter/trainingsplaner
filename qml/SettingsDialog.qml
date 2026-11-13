import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

AppDialog {
    id: dialog
    title: "Einstellungen"
    // Wide enough for the grid of Leerzeilen, Schriftgröße and Seitenränder
    width: Math.min(parent ? parent.width - 40 : 880, 880)
    standardButtons: Dialog.Save | Dialog.Cancel

    property var printOpts: ({})
    property var times: []

    // The spin boxes of the print settings, all as wide, room for a value
    // with its unit
    readonly property int fieldWidth: 108
    // A margin field has its edge icon before the value as well
    readonly property int marginWidth: fieldWidth + 28
    readonly property var papers: ["A4", "A5", "A3"]

    onAboutToShow: {
        trainerField.text = Store.trainer
        organisationField.text = Store.organisation
        printOpts = Store.printOptions
        times = Store.sessionTimes
        weekNote.checked = printOpts.weekNote
        weekNoteCentered.checked = printOpts.weekNoteCentered
        figures.checked = printOpts.figures
        sessionNoteCentered.checked = printOpts.sessionNoteCentered
        fraction.checked = printOpts.notation !== "slash"
        slash.checked = printOpts.notation === "slash"
        blankHeader.value = printOpts.blankHeader
        blankPerSession.value = printOpts.blankPerSession
        blankAfterNote.value = printOpts.blankAfterNote
        fontSmall.value = printOpts.fontSmall
        fontNormal.value = printOpts.fontNormal
        fontLarge.value = printOpts.fontLarge
        marginTop.value = printOpts.marginTop
        marginLeft.value = printOpts.marginLeft
        marginRight.value = printOpts.marginRight
        marginBottom.value = printOpts.marginBottom
        landscape.checked = printOpts.landscape
        portrait.checked = !printOpts.landscape
        paper.currentIndex = Math.max(0, papers.indexOf(printOpts.paper))
        logoPath.text = printOpts.logoPath
        sessionColor.color = printOpts.sessionColor
        for (let i = 0; i < 3; ++i) {
            // Set, not bound: the field writes its text itself (a picked
            // time, 8 written out as 08:00), which would end a binding
            timeRepeater.itemAt(i).fromField.text = times[i].from
            timeRepeater.itemAt(i).toField.text = times[i].to
        }
        kaderFilter.currentIndex = Math.max(0, kaderFilter.find(Store.filterKader))
        sexAll.checked = Store.filterSex < 0
        sexMen.checked = Store.filterSex === 0
        sexWomen.checked = Store.filterSex === 1
        categoryModel.clear()
        for (const c of Store.infoCategories)
            categoryModel.append({ name: c.name, code: c.code, unit: c.unit, decimals: c.decimals, aggregate: c.aggregate })
        step25.checked = Store.weightStep !== 1
        step10.checked = Store.weightStep === 1
        schemeBefore = Store.colorScheme
    }

    // The colours change at once as a preview; Abbrechen goes back
    property string schemeBefore: "system"
    onRejected: Store.colorScheme = schemeBefore

    onAccepted: {
        Store.trainer = trainerField.text.trim()
        Store.organisation = organisationField.text.trim()
        Store.printOptions = {
            weekNote: weekNote.checked,
            weekNoteCentered: weekNoteCentered.checked,
            figures: figures.checked,
            sessionNoteCentered: sessionNoteCentered.checked,
            notation: slash.checked ? "slash" : "fraction",
            blankHeader: blankHeader.value,
            blankPerSession: blankPerSession.value,
            blankAfterNote: blankAfterNote.value,
            fontSmall: fontSmall.value,
            fontNormal: fontNormal.value,
            fontLarge: fontLarge.value,
            marginTop: marginTop.value,
            marginLeft: marginLeft.value,
            marginRight: marginRight.value,
            marginBottom: marginBottom.value,
            landscape: landscape.checked,
            paper: paper.currentText,
            logoPath: logoPath.text,
            sessionColor: sessionColor.color.toString()
        }
        const t = []
        for (let i = 0; i < 3; ++i)
            t.push({ from: timeRepeater.itemAt(i).fromTime, to: timeRepeater.itemAt(i).toTime })
        Store.sessionTimes = t
        Store.weightStep = step10.checked ? 1 : 2.5
        const cats = []
        for (let i = 0; i < categoryModel.count; ++i)
            cats.push(categoryModel.get(i))
        Store.infoCategories = cats
        Store.filterKader = kaderFilter.currentIndex > 0 ? kaderFilter.currentText : ""
        Store.filterSex = sexMen.checked ? 0 : sexWomen.checked ? 1 : -1
    }

    contentItem: DialogScroll {
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            AppTabBar {
                id: tabs
                Layout.fillWidth: true
                AppTabButton { text: "Ausdruck" }
                AppTabButton { text: "Trainingszeiten" }
                AppTabButton { text: "Zusatzinfo" }
                AppTabButton { text: "Allgemein" }
            }

            StackLayout {
                id: pages
                currentIndex: tabs.currentIndex
                Layout.fillWidth: true
                // As high as the tallest page, so the dialog keeps its height
                // when the tab changes (a StackLayout reports only the current
                // page's). The hidden pages get the width as well, or wrapped
                // text in them would be measured unwrapped, too short.
                Layout.preferredHeight: {
                    let tallest = 0
                    for (const page of children)
                        tallest = Math.max(tallest, page.implicitHeight)
                    return tallest
                }

                // Printing: one grid, the row's label first, then label and
                // field pairs, so the fields stand in columns from row to row;
                // the last column takes what is left, so the wide fields reach
                // the edge
                GridLayout {
                    width: pages.width
                    columns: 10
                    columnSpacing: 8
                    rowSpacing: 8

                    Label { text: "Trainer:"; Layout.rightMargin: 8 }
                    TextField { id: trainerField; Layout.columnSpan: 9; Layout.fillWidth: true }
                    Label { text: "Kopfzeile rechts:"; Layout.rightMargin: 8 }
                    TextField { id: organisationField; Layout.columnSpan: 9; Layout.fillWidth: true; placeholderText: "z.B. Verein" }

                    Label { text: "Inhalt:"; Layout.alignment: Qt.AlignTop; Layout.rightMargin: 8 }
                    GridLayout {
                        Layout.columnSpan: 9
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 0
                        CheckBox { id: weekNote; text: "Wochenbemerkung" }
                        CheckBox { id: weekNoteCentered; text: "zentriert"; enabled: weekNote.checked }
                        CheckBox { id: figures; text: "Kennziffern der Woche (K1–K7)" }
                        CheckBox { id: sessionNoteCentered; text: "TE-Bemerkung zentriert" }
                    }

                    Label { text: "Laststufen:"; Layout.rightMargin: 8 }
                    RowLayout {
                        Layout.columnSpan: 9
                        spacing: 8
                        RadioButton { id: fraction; text: "Bruch (Gewicht über Wiederholungen)" }
                        RadioButton { id: slash; text: "100/2/2" }
                    }

                    Label { text: "Leerzeilen:"; Layout.rightMargin: 8 }
                    Label { text: "Kopf" }
                    SpinBox { id: blankHeader; from: 0; to: 20; editable: true; Layout.preferredWidth: dialog.fieldWidth }
                    Label { text: "je TE" }
                    SpinBox { id: blankPerSession; from: 0; to: 20; editable: true; Layout.preferredWidth: dialog.fieldWidth }
                    Label { text: "nach Bemerkung" }
                    SpinBox { id: blankAfterNote; from: 0; to: 40; editable: true; Layout.preferredWidth: dialog.fieldWidth; Layout.columnSpan: 4 }

                    Label { text: "Schriftgröße:"; Layout.rightMargin: 8 }
                    Label { text: "klein" }
                    SpinBox { id: fontSmall; unit: "pt"; from: 5; to: 24; editable: true; Layout.preferredWidth: dialog.fieldWidth }
                    Label { text: "normal" }
                    SpinBox { id: fontNormal; unit: "pt"; from: 6; to: 28; editable: true; Layout.preferredWidth: dialog.fieldWidth }
                    Label { text: "groß" }
                    SpinBox { id: fontLarge; unit: "pt"; from: 6; to: 36; editable: true; Layout.preferredWidth: dialog.fieldWidth; Layout.columnSpan: 4 }

                    // The page: its size, A4 unless chosen, and which way up
                    Label { text: "Papier:"; Layout.rightMargin: 8 }
                    Label { text: "Format" }
                    ComboBox { id: paper; model: dialog.papers; Layout.preferredWidth: dialog.fieldWidth }
                    RowLayout {
                        Layout.columnSpan: 7
                        spacing: 16
                        RadioButton { id: portrait; text: "Hochformat"; icon.source: Theme.icon("rectangle-vertical") }
                        RadioButton { id: landscape; text: "Querformat"; icon.source: Theme.icon("rectangle-horizontal") }
                    }

                    // Left and right, then top and bottom, each with the edge
                    // it keeps free
                    Label { text: "Seitenränder:"; Layout.rightMargin: 8 }
                    Label { text: "links" }
                    SpinBox { id: marginLeft; leadingIcon: Theme.icon("panel-left"); unit: "mm"; from: 0; to: 80; editable: true; Layout.preferredWidth: dialog.marginWidth }
                    Label { text: "rechts" }
                    SpinBox { id: marginRight; leadingIcon: Theme.icon("panel-right"); unit: "mm"; from: 0; to: 80; editable: true; Layout.preferredWidth: dialog.marginWidth; Layout.columnSpan: 5 }
                    Item { Layout.fillWidth: true }

                    Item {}
                    Label { text: "oben" }
                    SpinBox { id: marginTop; leadingIcon: Theme.icon("panel-top"); unit: "mm"; from: 0; to: 80; editable: true; Layout.preferredWidth: dialog.marginWidth }
                    Label { text: "unten" }
                    SpinBox { id: marginBottom; leadingIcon: Theme.icon("panel-bottom"); unit: "mm"; from: 0; to: 80; editable: true; Layout.preferredWidth: dialog.marginWidth; Layout.columnSpan: 6 }

                    Label { text: "Farbe TE-Zeile:"; Layout.rightMargin: 8 }
                    RowLayout {
                        Layout.columnSpan: 9
                        spacing: 8
                        Rectangle {
                            id: sessionColor
                            implicitWidth: 40
                            implicitHeight: 24
                            radius: 4
                            border.color: Styles.TokenInterface.semantics.stroke_subtle
                            MouseArea { anchors.fill: parent; onClicked: colorDialog.open() }
                        }
                        Button { text: "Weiß"; onClicked: sessionColor.color = "#ffffff" }
                    }

                    Label { text: "Logo im Hintergrund:"; Layout.rightMargin: 8 }
                    // Choosing and removing are buttons in the field, removing
                    // only while there is a logo
                    TextField {
                        id: logoPath
                        Layout.columnSpan: 9
                        Layout.fillWidth: true
                        placeholderText: "kein Logo"
                        readOnly: true
                        trailingItems: [
                            FieldButton {
                                iconName: "folder-open"
                                toolTip: "Bild wählen"
                                onClicked: logoDialog.open()
                            },
                            FieldButton {
                                visible: logoPath.text !== ""
                                iconName: "x"
                                toolTip: "Kein Logo"
                                onClicked: logoPath.text = ""
                            }
                        ]
                    }
                }

                // Default times of the sessions
                ColumnLayout {
                    width: pages.width
                    spacing: 8
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Neue Trainingseinheiten übernehmen die Zeiten einer anderen Einheit mit derselben Nummer in der Woche, sonst diese:"
                    }
                    Repeater {
                        id: timeRepeater
                        model: 3
                        RowLayout {
                            required property int index
                            readonly property alias fromField: _fromField
                            readonly property alias toField: _toField
                            // What is no time is not kept
                            readonly property string fromTime: _fromField.valid ? _fromField.time : ""
                            readonly property string toTime: _toField.valid ? _toField.time : ""
                            spacing: 8
                            Label { text: (index + 1) + ". TE"; Layout.preferredWidth: 50 }
                            Label { text: "von:" }
                            TimeField {
                                id: _fromField
                                objectName: "fromTime" + index
                            }
                            Label { text: "bis:" }
                            TimeField {
                                id: _toField
                                objectName: "toTime" + index
                            }
                            RangeLink { from: _fromField; to: _toField }
                        }
                    }
                }

                // Categories of extra info
                ColumnLayout {
                    width: pages.width
                    id: categoryTab
                    spacing: 4
                    // Column widths shared by the headings and the rows, wide
                    // enough for the headings; the name takes the rest
                    readonly property int wCode: 72
                    readonly property int wUnit: 72
                    readonly property int wDecimals: 112
                    readonly property int wWeek: 136
                    readonly property int wRemove: 32
                    RowLayout {
                        spacing: 8
                        Layout.rightMargin: categoryTab.wRemove + 8 + categoryBar.room
                        Label { text: "Bezeichnung"; Layout.fillWidth: true; font.pixelSize: 11 }
                        Label { text: "Kürzel"; Layout.preferredWidth: categoryTab.wCode; font.pixelSize: 11 }
                        Label { text: "Einheit"; Layout.preferredWidth: categoryTab.wUnit; font.pixelSize: 11 }
                        Label { text: "Nachkomma"; Layout.preferredWidth: categoryTab.wDecimals; font.pixelSize: 11 }
                        Label { text: "Woche"; Layout.preferredWidth: categoryTab.wWeek; font.pixelSize: 11 }
                    }
                    ListView {
                        boundsBehavior: Flickable.StopAtBounds
                        id: categoryList
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        clip: true
                        // The normal form spacing between the rows
                        spacing: 8
                        model: ListModel { id: categoryModel }
                        ScrollBar.vertical: AppScrollBar { id: categoryBar }
                        delegate: RowLayout {
                            width: ListView.view.width - categoryBar.room
                            required property int index
                            required property string name
                            required property string code
                            required property string unit
                            required property int decimals
                            required property string aggregate
                            spacing: 8
                            TextField { Layout.fillWidth: true; text: name; onTextEdited: categoryModel.setProperty(index, "name", text) }
                            TextField { Layout.preferredWidth: categoryTab.wCode; text: code; onTextEdited: categoryModel.setProperty(index, "code", text) }
                            TextField { Layout.preferredWidth: categoryTab.wUnit; text: unit; onTextEdited: categoryModel.setProperty(index, "unit", text) }
                            SpinBox { Layout.preferredWidth: categoryTab.wDecimals; from: 0; to: 3; value: decimals; onValueModified: categoryModel.setProperty(index, "decimals", value) }
                            ComboBox {
                                Layout.preferredWidth: categoryTab.wWeek
                                model: [{ text: "Maximum", v: "MAX" }, { text: "Minimum", v: "MIN" }, { text: "Summe", v: "SUM" }]
                                textRole: "text"
                                valueRole: "v"
                                Component.onCompleted: currentIndex = indexOfValue(aggregate)
                                onActivated: categoryModel.setProperty(index, "aggregate", currentValue)
                            }
                            IconToolButton {
                                Layout.preferredWidth: categoryTab.wRemove
                                Layout.preferredHeight: categoryTab.wRemove
                                iconName: "trash-2"
                                toolTip: "Entfernen"
                                onClicked: categoryModel.remove(index)
                            }
                        }
                    }
                    IconButton {
                        iconName: "plus"
                        text: "Kategorie hinzufügen"
                        onClicked: categoryModel.append({ name: "", code: "", unit: "", decimals: 0, aggregate: "MAX" })
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "„Woche“ legt fest, welcher Wert in der Wochenübersicht steht. Das Kürzel ordnet gespeicherte Werte zu; bitte nicht ändern, wenn schon Werte erfasst sind."
                    }
                }

                // General
                GridLayout {
                    width: pages.width
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 8
                    Label { text: "Sportlerauswahl:" }
                    RowLayout {
                        spacing: 8
                        ComboBox {
                            id: kaderFilter
                            implicitWidth: 160
                            model: ["alle Kader"].concat(Store.attributeValues("Kader"))
                        }
                        RadioButton { id: sexAll; text: "alle" }
                        RadioButton { id: sexMen; text: "Männer" }
                        RadioButton { id: sexWomen; text: "Frauen" }
                    }
                    Label {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Gilt für die Auswahllisten im Wochenplan, in der Planung und in den Analysen."
                    }
                    Label { text: "Steigerung:" }
                    RowLayout {
                        spacing: 8
                        RadioButton { id: step25; text: "2,5 kg" }
                        RadioButton { id: step10; text: "1,0 kg" }
                    }
                    Label {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Pfeiltasten in Gewichtsfeldern und berechnete Gewichte springen in diesen Schritten."
                    }
                    Label { text: "Datenbank:" }
                    TextField { Layout.fillWidth: true; readOnly: true; selectByMouse: true; text: Store.databasePath }
                    Label {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Alle Daten stehen in dieser einen Datei. Zur Sicherung das Programm schließen und die Datei kopieren, oder Daten › Exportieren nutzen."
                    }
                    Label { text: "Farbschema:" }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: [{ value: "system", text: "wie das System" }, { value: "light", text: "Hell" },
                                    { value: "dark", text: "Dunkel" }, { value: "classic", text: "Klassisch" }]
                            RadioButton {
                                required property var modelData
                                objectName: "scheme_" + modelData.value
                                text: modelData.text
                                checked: Store.colorScheme === modelData.value
                                onToggled: if (checked) Store.colorScheme = modelData.value
                            }
                        }
                    }
                    Label {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Klassisch: die Farben des alten Programms, mit den gelben Kästen im Wochenplan."
                    }
                    Label {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        color: Styles.TokenInterface.semantics.text_muted
                        text: "Version und Updates: Hilfe › Über den Trainingsplaner."
                    }
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        selectedColor: sessionColor.color
        onAccepted: sessionColor.color = selectedColor
    }

    FileDialog {
        id: logoDialog
        title: "Logo wählen"
        nameFilters: ["Bilder (*.png *.jpg *.jpeg *.bmp *.gif)"]
        onAccepted: logoPath.text = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
    }
}
