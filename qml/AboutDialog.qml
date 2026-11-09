import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Hilfe › Über den Trainingsplaner: version, updates, where to report
// problems, licences
AppDialog {
    id: dialog

    readonly property string state: Updater.state
    readonly property bool busy: state === "checking" || state === "downloading" || state === "installing"

    signal showUpdateDetails()

    title: "Über den Trainingsplaner"
    width: parent ? Math.min(parent.width - 40, 560) : 560
    standardButtons: Dialog.Close
    closePolicy: busy ? Popup.NoAutoClose : Popup.CloseOnEscape

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        RowLayout {
            spacing: 12
            Image {
                source: "qrc:/qt/qml/Trainingsplaner/logo/trainingsplaner.svg"
                sourceSize: Qt.size(64, 64)
                Layout.alignment: Qt.AlignTop
            }
            ColumnLayout {
                spacing: 2
                Label {
                    text: "Trainingsplaner Gewichtheben"
                    font.pixelSize: 18
                    font.bold: true
                }
                Label {
                    objectName: "versionLabel"
                    text: "Version " + Updater.currentVersion
                }
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    wrapMode: Text.Wrap
                    color: palette.placeholderText
                    text: "Wochenpläne, Planung, Analysen und Wettkämpfe für das Gewichtheben. Freie Software."
                }
            }
        }

        // Updates
        Frame {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    objectName: "updateStatus"
                    wrapMode: Text.Wrap
                    font.bold: dialog.state === "available"
                    color: dialog.state === "error" ? Theme.error : palette.windowText
                    text: {
                        switch (dialog.state) {
                        case "checking": return "Suche nach einer neuen Version …"
                        case "upToDate": return "Sie verwenden die neueste Version."
                        case "available": return "Version " + Updater.latestVersion + " ist verfügbar."
                        case "downloading": return "Version " + Updater.latestVersion + " wird heruntergeladen …"
                        case "installing": return "Die neue Version wird installiert. Das Programm startet gleich neu."
                        case "error": return Updater.error
                        }
                        return "Noch nicht nach einer neuen Version gesucht."
                    }
                }
                ProgressBar {
                    Layout.fillWidth: true
                    visible: dialog.state === "downloading" || dialog.state === "installing"
                    value: Updater.progress
                }
                RowLayout {
                    spacing: 8
                    Button {
                        objectName: "checkButton"
                        text: "Nach Updates suchen"
                        enabled: !dialog.busy
                        onClicked: Updater.check()
                    }
                    Button {
                        objectName: "installButton"
                        visible: dialog.state === "available"
                        highlighted: true
                        text: Updater.installsItself ? "Jetzt aktualisieren" : "Herunterladen"
                        onClicked: Updater.install()
                    }
                    Button {
                        visible: dialog.state === "available" && Updater.notes !== ""
                        text: "Was ist neu?"
                        onClicked: dialog.showUpdateDetails()
                    }
                    Button {
                        visible: dialog.state === "downloading"
                        text: "Abbrechen"
                        onClicked: Updater.cancel()
                    }
                }
                CheckBox {
                    text: "Beim Start automatisch nach neuen Versionen suchen"
                    checked: Updater.autoCheck
                    onToggled: Updater.autoCheck = checked
                    padding: 0
                }
            }
        }

        // Links
        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 8
            Label { text: "Probleme, Wünsche:" }
            Label {
                textFormat: Text.StyledText
                text: "<a href=\"" + Updater.issueUrl + "\">Auf GitHub melden</a> (GitHub-Konto nötig)"
                linkColor: Theme.link
                onLinkActivated: (link) => Qt.openUrlExternally(link)
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Label { text: "Webseite:" }
            Label {
                textFormat: Text.StyledText
                text: "<a href=\"https://iam-peter.github.io/trainingsplaner/\">iam-peter.github.io/trainingsplaner</a>"
                linkColor: Theme.link
                onLinkActivated: (link) => Qt.openUrlExternally(link)
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Label { text: "Quellcode:" }
            Label {
                textFormat: Text.StyledText
                text: "<a href=\"https://github.com/iam-peter/trainingsplaner\">github.com/iam-peter/trainingsplaner</a>"
                linkColor: Theme.link
                onLinkActivated: (link) => Qt.openUrlExternally(link)
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Label { text: "System:" }
            Label {
                Layout.fillWidth: true
                text: Updater.systemInfo
                color: palette.placeholderText
                wrapMode: Text.Wrap
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: palette.placeholderText
            textFormat: Text.StyledText
            text: "MIT-Lizenz. Verwendet Qt (LGPL v3), die Schriften Inter und JetBrains Mono (SIL Open Font License) "
                  + "und Lucide-Symbole (ISC). <a href=\"https://iam-peter.github.io/trainingsplaner/hinweise.html\">Hinweise und Lizenzen</a>"
            linkColor: Theme.link
            onLinkActivated: (link) => Qt.openUrlExternally(link)
        }
    }
}
