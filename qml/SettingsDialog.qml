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
    width: Math.min(parent ? parent.width - 40 : 840, 840)
    standardButtons: Dialog.Save | Dialog.Cancel

    property var printOpts: ({})
    property var times: []

    // The label columns of Leerzeilen, Schriftgröße and Seitenränder
    readonly property real col1: Math.max(col1a.implicitWidth, col1b.implicitWidth, col1c.implicitWidth)
    readonly property real col2: Math.max(col2a.implicitWidth, col2b.implicitWidth, col2c.implicitWidth)
    readonly property real col3: Math.max(col3a.implicitWidth, col3b.implicitWidth, col3c.implicitWidth)

    function cm(mm) { return (mm / 10).toLocaleString(Qt.locale("de_DE"), "f", 1) }
    function mm(text) {
        const v = Number.fromLocaleString(Qt.locale("de_DE"), text.trim() === "" ? "0" : text)
        return isNaN(v) ? 0 : v * 10
    }

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
        marginTop.text = cm(printOpts.marginTop)
        marginLeft.text = cm(printOpts.marginLeft)
        marginRight.text = cm(printOpts.marginRight)
        marginBottom.text = cm(printOpts.marginBottom)
        landscape.checked = printOpts.landscape
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
            marginTop: mm(marginTop.text),
            marginLeft: mm(marginLeft.text),
            marginRight: mm(marginRight.text),
            marginBottom: mm(marginBottom.text),
            landscape: landscape.checked,
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

    contentItem: ColumnLayout {
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
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true

            // Printing
            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 8

                Label { text: "Trainer:" }
                TextField { id: trainerField; Layout.fillWidth: true }
                Label { text: "Kopfzeile rechts:" }
                TextField { id: organisationField; Layout.fillWidth: true; placeholderText: "z.B. Verein" }

                Label { text: "Inhalt:"; Layout.alignment: Qt.AlignTop }
                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 0
                    CheckBox { id: weekNote; text: "Wochenbemerkung" }
                    CheckBox { id: weekNoteCentered; text: "zentriert"; enabled: weekNote.checked }
                    CheckBox { id: figures; text: "Kennziffern der Woche (K1–K7)" }
                    CheckBox { id: sessionNoteCentered; text: "TE-Bemerkung zentriert" }
                }

                Label { text: "Laststufen:" }
                RowLayout {
                    spacing: 8
                    RadioButton { id: fraction; text: "Bruch (Gewicht über Wiederholungen)" }
                    RadioButton { id: slash; text: "100/2/2" }
                }

                // Leerzeilen, Schriftgröße and Seitenränder as one grid: each
                // label column as wide as its widest label, every field 90 px,
                // so the fields stand in columns from row to row
                Label { text: "Leerzeilen:" }
                RowLayout {
                    spacing: 8
                    Label { id: col1a; text: "Kopf"; Layout.preferredWidth: dialog.col1 }
                    SpinBox { id: blankHeader; from: 0; to: 20; editable: true; Layout.preferredWidth: 90 }
                    Label { id: col2a; text: "je TE"; Layout.preferredWidth: dialog.col2 }
                    SpinBox { id: blankPerSession; from: 0; to: 20; editable: true; Layout.preferredWidth: 90 }
                    Label { id: col3a; text: "nach Bemerkung"; Layout.preferredWidth: dialog.col3 }
                    SpinBox { id: blankAfterNote; from: 0; to: 40; editable: true; Layout.preferredWidth: 90 }
                }

                Label { text: "Schriftgröße (pt):" }
                RowLayout {
                    spacing: 8
                    Label { id: col1b; text: "klein"; Layout.preferredWidth: dialog.col1 }
                    SpinBox { id: fontSmall; from: 5; to: 24; editable: true; Layout.preferredWidth: 90 }
                    Label { id: col2b; text: "normal"; Layout.preferredWidth: dialog.col2 }
                    SpinBox { id: fontNormal; from: 6; to: 28; editable: true; Layout.preferredWidth: 90 }
                    Label { id: col3b; text: "groß"; Layout.preferredWidth: dialog.col3 }
                    SpinBox { id: fontLarge; from: 6; to: 36; editable: true; Layout.preferredWidth: 90 }
                }

                Label { text: "Seitenränder (cm):" }
                RowLayout {
                    spacing: 8
                    Label { id: col1c; text: "oben"; Layout.preferredWidth: dialog.col1 }
                    TextField { id: marginTop; Layout.preferredWidth: 90; horizontalAlignment: TextInput.AlignHCenter }
                    Label { id: col2c; text: "links"; Layout.preferredWidth: dialog.col2 }
                    TextField { id: marginLeft; Layout.preferredWidth: 90; horizontalAlignment: TextInput.AlignHCenter }
                    Label { id: col3c; text: "rechts"; Layout.preferredWidth: dialog.col3 }
                    TextField { id: marginRight; Layout.preferredWidth: 90; horizontalAlignment: TextInput.AlignHCenter }
                    Label { text: "unten" }
                    TextField { id: marginBottom; Layout.preferredWidth: 90; horizontalAlignment: TextInput.AlignHCenter }
                }
                Item { implicitWidth: 1 }
                CheckBox { id: landscape; text: "Querformat" }

                Label { text: "Farbe TE-Zeile:" }
                RowLayout {
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

                Label { text: "Logo im Hintergrund:" }
                RowLayout {
                    spacing: 8
                    TextField { id: logoPath; Layout.fillWidth: true; placeholderText: "kein Logo"; readOnly: true }
                    IconButton { iconName: "folder-open"; toolTip: "Bild wählen"; onClicked: logoDialog.open() }
                    IconButton { iconName: "x"; toolTip: "Kein Logo"; onClicked: logoPath.text = "" }
                }
            }

            // Default times of the sessions
            ColumnLayout {
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
                        readonly property alias fromField: fromField
                        readonly property alias toField: toField
                        // What is no time is not kept
                        readonly property string fromTime: fromField.valid ? fromField.time : ""
                        readonly property string toTime: toField.valid ? toField.time : ""
                        spacing: 8
                        Label { text: (index + 1) + ". TE"; Layout.preferredWidth: 50 }
                        Label { text: "von:" }
                        TimeField {
                            id: fromField
                            objectName: "fromTime" + index
                        }
                        Label { text: "bis:" }
                        TimeField {
                            id: toField
                            objectName: "toTime" + index
                        }
                    }
                }
            }

            // Categories of extra info
            ColumnLayout {
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
