import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// A new version: what is new, and updating with one click (Windows,
// installed with the installer) or downloading it (macOS, Linux, zip)
AppDialog {
    id: dialog

    readonly property string state: Updater.state
    readonly property bool busy: state === "checking" || state === "downloading" || state === "installing"

    title: "Programmversion"
    width: parent ? Math.min(parent.width - 40, 620) : 620
    closePolicy: busy ? Popup.NoAutoClose : Popup.CloseOnEscape

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.bold: true
            text: {
                switch (dialog.state) {
                case "checking": return "Suche nach einer neuen Version …"
                case "upToDate": return "Sie verwenden die neueste Version (" + Updater.currentVersion + ")."
                case "available": return "Version " + Updater.latestVersion + " ist verfügbar (installiert: " + Updater.currentVersion + ")."
                case "downloading": return "Version " + Updater.latestVersion + " wird heruntergeladen …"
                case "installing": return "Die neue Version wird installiert. Das Programm startet gleich neu."
                case "error": return "Das hat nicht geklappt."
                }
                return "Installiert: Version " + Updater.currentVersion
            }
        }

        Label {
            Layout.fillWidth: true
            visible: dialog.state === "error"
            wrapMode: Text.Wrap
            color: "#c00000"
            text: Updater.error
        }

        Label {
            Layout.fillWidth: true
            visible: dialog.state === "available" && !Updater.installsItself
            wrapMode: Text.Wrap
            color: palette.placeholderText
            text: Qt.platform.os === "osx"
                  ? "„Herunterladen“ lädt das neue Programm. Danach das Programm beenden und die neue Version aus dem Fenster in den Programme-Ordner ziehen."
                  : "„Herunterladen“ öffnet die Download-Seite. Ihre Daten bleiben beim Wechsel der Version erhalten."
        }

        ProgressBar {
            Layout.fillWidth: true
            visible: dialog.state === "downloading" || dialog.state === "installing"
            value: Updater.progress
        }

        Label {
            visible: notesView.visible
            text: "Neu in dieser Version:"
        }
        ScrollView {
            id: notesView
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            visible: Updater.notes !== "" && (dialog.state === "available" || dialog.state === "downloading")
            clip: true
            contentWidth: availableWidth
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                textFormat: Text.MarkdownText
                text: Updater.notes
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    // A fixed order on every system: details left, the action right
    footer: Pane {
        RowLayout {
            anchors.fill: parent
            spacing: 8
            Button {
                text: "Auf GitHub ansehen"
                visible: Updater.releasePage.toString() !== "" && !dialog.busy
                onClicked: Qt.openUrlExternally(Updater.releasePage)
            }
            Item { Layout.fillWidth: true }
            Button {
                visible: dialog.state === "upToDate" || (dialog.state === "error" && Updater.latestVersion === "")
                text: "Erneut suchen"
                onClicked: Updater.check()
            }
            Button {
                text: dialog.state === "downloading" ? "Abbrechen" : "Schließen"
                enabled: dialog.state !== "installing" && dialog.state !== "checking"
                onClicked: dialog.state === "downloading" ? Updater.cancel() : dialog.close()
            }
            Button {
                objectName: "updateButton"
                visible: dialog.state === "available" || (dialog.state === "error" && Updater.latestVersion !== "")
                text: Updater.installsItself ? "Jetzt aktualisieren" : "Herunterladen"
                highlighted: true
                onClicked: Updater.install()
            }
        }
    }
}
