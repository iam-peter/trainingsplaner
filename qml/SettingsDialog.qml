import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

Dialog {
    id: dialog
    title: "Einstellungen"
    modal: true
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - 40 : 720, 720)
    standardButtons: Dialog.Save | Dialog.Cancel

    property var printOpts: ({})
    property var times: []

    readonly property var timeChoices: {
        const list = [""]
        for (let h = 6; h <= 23; ++h)
            for (let m = 0; m < 60; m += 15)
                list.push((h < 10 ? "0" : "") + h + ":" + (m === 0 ? "00" : m))
        return list
    }

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
            timeRepeater.itemAt(i).from = times[i].from
            timeRepeater.itemAt(i).to = times[i].to
        }
        kaderFilter.currentIndex = Math.max(0, kaderFilter.find(Store.filterKader))
        sexAll.checked = Store.filterSex < 0
        sexMen.checked = Store.filterSex === 0
        sexWomen.checked = Store.filterSex === 1
        step25.checked = Store.weightStep !== 1
        step10.checked = Store.weightStep === 1
    }

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
            t.push({ from: timeRepeater.itemAt(i).from, to: timeRepeater.itemAt(i).to })
        Store.sessionTimes = t
        Store.weightStep = step10.checked ? 1 : 2.5
        Store.filterKader = kaderFilter.currentIndex > 0 ? kaderFilter.currentText : ""
        Store.filterSex = sexMen.checked ? 0 : sexWomen.checked ? 1 : -1
    }

    contentItem: ColumnLayout {
        spacing: 10

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "Ausdruck" }
            TabButton { text: "Trainingszeiten" }
            TabButton { text: "Allgemein" }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true

            // Printing
            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 6

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
                    RadioButton { id: fraction; text: "Bruch (Gewicht über Wiederholungen)" }
                    RadioButton { id: slash; text: "100/2/2" }
                }

                Label { text: "Leerzeilen:" }
                RowLayout {
                    spacing: 6
                    Label { text: "Kopf" }
                    SpinBox { id: blankHeader; from: 0; to: 20; editable: true; implicitWidth: 90 }
                    Label { text: "je TE" }
                    SpinBox { id: blankPerSession; from: 0; to: 20; editable: true; implicitWidth: 90 }
                    Label { text: "nach Bemerkung" }
                    SpinBox { id: blankAfterNote; from: 0; to: 40; editable: true; implicitWidth: 90 }
                }

                Label { text: "Schriftgröße (pt):" }
                RowLayout {
                    spacing: 6
                    Label { text: "klein" }
                    SpinBox { id: fontSmall; from: 5; to: 24; editable: true; implicitWidth: 90 }
                    Label { text: "normal" }
                    SpinBox { id: fontNormal; from: 6; to: 28; editable: true; implicitWidth: 90 }
                    Label { text: "groß" }
                    SpinBox { id: fontLarge; from: 6; to: 36; editable: true; implicitWidth: 90 }
                }

                Label { text: "Seitenränder (cm):" }
                RowLayout {
                    spacing: 6
                    Label { text: "oben" }
                    TextField { id: marginTop; implicitWidth: 50; horizontalAlignment: TextInput.AlignHCenter }
                    Label { text: "links" }
                    TextField { id: marginLeft; implicitWidth: 50; horizontalAlignment: TextInput.AlignHCenter }
                    Label { text: "rechts" }
                    TextField { id: marginRight; implicitWidth: 50; horizontalAlignment: TextInput.AlignHCenter }
                    Label { text: "unten" }
                    TextField { id: marginBottom; implicitWidth: 50; horizontalAlignment: TextInput.AlignHCenter }
                    CheckBox { id: landscape; text: "Querformat" }
                }

                Label { text: "Farbe TE-Zeile:" }
                RowLayout {
                    Rectangle {
                        id: sessionColor
                        implicitWidth: 40
                        implicitHeight: 24
                        radius: 4
                        border.color: palette.mid
                        MouseArea { anchors.fill: parent; onClicked: colorDialog.open() }
                    }
                    Button { text: "Weiß"; onClicked: sessionColor.color = "#ffffff" }
                }

                Label { text: "Logo im Hintergrund:" }
                RowLayout {
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
                    color: palette.placeholderText
                    text: "Neue Trainingseinheiten übernehmen die Zeiten einer anderen Einheit mit derselben Nummer in der Woche, sonst diese:"
                }
                Repeater {
                    id: timeRepeater
                    model: 3
                    RowLayout {
                        required property int index
                        property string from
                        property string to
                        spacing: 8
                        Label { text: (index + 1) + ". TE"; Layout.preferredWidth: 50 }
                        Label { text: "von:" }
                        ComboBox {
                            editable: true
                            model: dialog.timeChoices
                            implicitWidth: 100
                            editText: parent.from
                            onEditTextChanged: parent.from = editText
                        }
                        Label { text: "bis:" }
                        ComboBox {
                            editable: true
                            model: dialog.timeChoices
                            implicitWidth: 100
                            editText: parent.to
                            onEditTextChanged: parent.to = editText
                        }
                    }
                }
            }

            // General
            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 6
                Label { text: "Sportlerauswahl:" }
                RowLayout {
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
                    color: palette.placeholderText
                    text: "Gilt für die Auswahllisten im Wochenplan, in der Planung und in den Analysen."
                }
                Label { text: "Steigerung:" }
                RowLayout {
                    RadioButton { id: step25; text: "2,5 kg" }
                    RadioButton { id: step10; text: "1,0 kg" }
                }
                Label {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: palette.placeholderText
                    text: "Pfeiltasten in Gewichtsfeldern und berechnete Gewichte springen in diesen Schritten."
                }
                Label { text: "Datenbank:" }
                TextField { Layout.fillWidth: true; readOnly: true; selectByMouse: true; text: Store.databasePath }
                Label {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: palette.placeholderText
                    text: "Alle Daten stehen in dieser einen Datei. Zur Sicherung das Programm schließen und die Datei kopieren, oder „Daten exportieren…“ nutzen."
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
