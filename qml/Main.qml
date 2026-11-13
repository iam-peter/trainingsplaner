import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Trainingsplaner

ApplicationWindow {
    id: window

    // Set from the command line (see main.cpp).
    property string startAthlete
    property string startWeek
    property string startPage
    property string startSession

    // The pages in the order of the tabs
    readonly property int athletesTab: 0
    readonly property int weekTab: 1
    readonly property int planningTab: 2
    readonly property int analysisTab: 3
    readonly property int competitionsTab: 4

    // The athlete all pages show: choosing one on any page selects them on
    // the others too
    property string athlete

    // The first athlete of the selection lists while none is chosen or the
    // chosen one is gone. Only here: pages that each picked one fought over
    // the athlete they are bound to (a binding loop).
    function chooseDefaultAthlete() {
        if (athlete !== "" && Store.athletes.some(a => a.id === athlete))
            return
        const list = Store.selectableAthletes.length > 0 ? Store.selectableAthletes : Store.athletes
        athlete = list.length > 0 ? list[0].id : ""
    }

    Connections {
        target: Store
        function onAthletesChanged() { window.chooseDefaultAthlete() }
    }

    width: 1366
    height: 900
    minimumWidth: 1000
    minimumHeight: 680
    visible: true
    title: Store.projectName + " – Trainingsplaner Gewichtheben"

    // The old program's colours, when chosen as colour scheme
    Binding {
        target: Styles.TokenInterface
        property: "classic"
        value: Store.classicColors
    }

    // The controls take the application palette, so a palette set by the
    // program (Einstellungen › Farbschema) reaches them as well as the system's
    palette.window: Styles.TokenInterface.semantics.background_default
    palette.windowText: Styles.TokenInterface.semantics.text_default
    palette.base: Styles.TokenInterface.semantics.background_elevated
    palette.alternateBase: Styles.TokenInterface.semantics.background_muted
    palette.text: Styles.TokenInterface.semantics.text_default
    palette.button: Styles.TokenInterface.semantics.background_secondary
    palette.buttonText: Styles.TokenInterface.semantics.text_default
    palette.highlight: Styles.TokenInterface.semantics.primary_default
    palette.highlightedText: Styles.TokenInterface.semantics.text_on_primary
    palette.placeholderText: Styles.TokenInterface.semantics.text_muted
    palette.mid: Styles.TokenInterface.semantics.stroke_subtle
    palette.dark: Styles.TokenInterface.semantics.stroke_focus
    palette.light: Styles.TokenInterface.semantics.background_default
    palette.toolTipBase: Styles.TokenInterface.semantics.primary_default
    palette.toolTipText: Styles.TokenInterface.semantics.text_on_primary
    palette.link: Styles.TokenInterface.semantics.text_default

    header: AppToolBar {
        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Everything that is not a page: projects, the old program's
            // data, settings and help
            IconToolButton {
                id: fileButton
                objectName: "fileButton"
                iconName: "dumbbell"
                text: "Datei"
                // Only the dumbbell, without a tooltip; the name stays for
                // screen readers
                display: AbstractButton.IconOnly
                onClicked: fileMenu.open()
                Menu {
                    id: fileMenu
                    objectName: "fileMenu"
                    y: fileButton.height
                    KeyMenuItem {
                        objectName: "newProjectItem"
                        text: "Neues Projekt…"
                        keys: "Strg+N"
                        icon.source: Theme.icon("file-plus")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: window.newProject()
                    }
                    KeyMenuItem {
                        text: "Öffnen…"
                        keys: "Strg+O"
                        icon.source: Theme.icon("folder-open")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: window.openProject()
                    }
                    Menu {
                        id: recentMenu
                        objectName: "recentMenu"
                        title: "Zuletzt geöffnet"
                        icon.source: Theme.icon("history")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        // The entry for it takes the whole icon, size too
                        icon.width: 16
                        icon.height: 16
                        Instantiator {
                            model: Store.recentProjects
                            delegate: MenuItem {
                                required property var modelData
                                text: modelData.name
                                ToolTip.text: modelData.path
                                ToolTip.visible: hovered
                                ToolTip.delay: 600
                                onTriggered: window.switchProject(() => Store.openProject(modelData.path))
                            }
                            onObjectAdded: (index, object) => recentMenu.insertItem(index, object)
                            onObjectRemoved: (index, object) => recentMenu.removeItem(object)
                        }
                        MenuItem {
                            visible: Store.recentProjects.length === 0
                            height: visible ? implicitHeight : 0
                            enabled: false
                            text: "Noch keine anderen Projekte"
                        }
                    }
                    KeyMenuItem {
                        text: "Speichern unter…"
                        keys: "Strg+Umschalt+S"
                        icon.source: Theme.icon("save")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: window.saveProjectAs()
                    }
                    MenuSeparator {}
                    MenuItem {
                        text: "Importieren…"
                        icon.source: Theme.icon("import")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: importDialog.open()
                    }
                    MenuItem {
                        text: "Exportieren…"
                        icon.source: Theme.icon("file-down")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: exportDialog.open()
                    }
                    MenuItem {
                        visible: Store.hasDemoData
                        height: visible ? implicitHeight : 0
                        text: "Beispieldaten entfernen"
                        icon.source: Theme.icon("trash-2")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: removeDemoConfirm.open()
                    }
                    MenuSeparator {}
                    MenuItem {
                        objectName: "settingsItem"
                        text: "Einstellungen…"
                        icon.source: Theme.icon("settings")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: settingsDialog.open()
                    }
                    MenuSeparator {}
                    KeyMenuItem {
                        text: "Hilfe"
                        keys: "F1"
                        icon.source: Theme.icon("circle-help")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: helpDialog.open()
                    }
                    MenuItem {
                        // && shows one &: a single one marks a shortcut key
                        text: "Ideen && Probleme"
                        icon.source: Theme.icon("external-link")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: Qt.openUrlExternally(Updater.issueUrl)
                    }
                    MenuItem {
                        text: "Über den Trainingsplaner"
                        icon.source: Theme.icon("info")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: aboutDialog.open()
                    }
                    MenuSeparator {}
                    KeyMenuItem {
                        text: "Beenden"
                        keys: "Strg+Q"
                        icon.source: Theme.icon("log-out")
                        icon.color: Styles.TokenInterface.semantics.text_default
                        onTriggered: window.close()
                    }
                }
            }

            AppTabBar {
                id: tabs
                objectName: "mainTabs"
                Layout.preferredWidth: 720
                currentIndex: window.weekTab
                AppTabButton { text: "Sportler"; iconName: "users" }
                AppTabButton { text: "Wochenplan"; iconName: "calendar-days" }
                AppTabButton { text: "Planung"; iconName: "target" }
                AppTabButton { text: "Analyse"; iconName: "chart-line" }
                AppTabButton { text: "Wettkämpfe"; iconName: "trophy" }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // Projects. What the session panel holds is saved into the open one
    // first, as on closing; the pages then show the other file's athletes.
    function switchProject(open) {
        if (!weekPage.closePanel()) {
            tabs.currentIndex = weekTab
            return false
        }
        const error = open()
        if (error !== "") {
            projectError.text = error
            projectError.open()
            return false
        }
        chooseDefaultAthlete()
        return true
    }
    function newProject() { newProjectDialog.open() }
    function openProject() { openProjectDialog.open() }
    function saveProjectAs() { saveProjectDialog.open() }

    Shortcut {
        sequences: [StandardKey.New]
        enabled: DialogStack.open === 0
        onActivated: window.newProject()
    }
    Shortcut {
        sequences: [StandardKey.Open]
        enabled: DialogStack.open === 0
        onActivated: window.openProject()
    }
    Shortcut {
        sequences: ["Ctrl+Shift+S"]
        enabled: DialogStack.open === 0
        onActivated: window.saveProjectAs()
    }
    Shortcut {
        sequences: [StandardKey.Quit, "Ctrl+Q"]
        onActivated: window.close()
    }

    readonly property var projectFilters: ["Trainingsplaner-Projekt (*.trainingsplaner *.sqlite)", "Alle Dateien (*)"]

    FileDialog {
        id: newProjectDialog
        title: "Neues Projekt"
        fileMode: FileDialog.SaveFile
        nameFilters: window.projectFilters
        defaultSuffix: "trainingsplaner"
        currentFolder: Store.projectFolder
        // An existing file is refused by the program, not replaced
        options: FileDialog.DontConfirmOverwrite
        onAccepted: if (window.switchProject(() => Store.newProject(selectedFile.toString())))
                        welcomeDialog.open()
    }
    FileDialog {
        id: openProjectDialog
        title: "Projekt öffnen"
        fileMode: FileDialog.OpenFile
        nameFilters: window.projectFilters
        currentFolder: Store.projectFolder
        onAccepted: window.switchProject(() => Store.openProject(selectedFile.toString()))
    }
    FileDialog {
        id: saveProjectDialog
        title: "Projekt speichern unter"
        fileMode: FileDialog.SaveFile
        nameFilters: window.projectFilters
        defaultSuffix: "trainingsplaner"
        currentFolder: Store.projectFolder
        onAccepted: window.switchProject(() => Store.saveProjectAs(selectedFile.toString()))
    }
    AppDialog {
        id: projectError
        objectName: "projectError"
        property alias text: projectErrorLabel.text
        title: "Projekt"
        standardButtons: Dialog.Ok
        ColumnLayout {
            Label {
                id: projectErrorLabel
                Layout.preferredWidth: 480
                wrapMode: Text.Wrap
            }
        }
    }

    // Undo and redo changes to sessions from every page; they show the week
    // that changed. Text fields keep their own Ctrl+Z.
    Shortcut {
        sequences: [StandardKey.Undo]
        enabled: DialogStack.open === 0 && Store.undoLabel !== ""
        // The panel's changes are saved first, so undo takes them back
        // rather than the panel writing them over the undone week later
        onActivated: if (weekPage.savePanel()) window.showChange(Store.undo())
    }
    Shortcut {
        sequences: [StandardKey.Redo, "Ctrl+Y"]
        enabled: DialogStack.open === 0 && Store.redoLabel !== ""
        onActivated: if (weekPage.savePanel()) window.showChange(Store.redo())
    }

    // What the session panel holds is saved before the program ends; when
    // it cannot be (an impossible time), the program stays open on it
    onClosing: (close) => {
        if (!weekPage.closePanel()) {
            close.accepted = false
            tabs.currentIndex = weekTab
        }
    }

    function showChange(change) {
        if (!change.athleteId)
            return
        athlete = change.athleteId
        weekPage.show(change)
        tabs.currentIndex = weekTab
    }

    // Ctrl+1 … Ctrl+5 switch pages, in the order of the tabs
    Repeater {
        model: 5
        Item {
            required property int index
            Shortcut {
                sequence: "Ctrl+" + (index + 1)
                enabled: DialogStack.open === 0
                onActivated: tabs.currentIndex = index
            }
        }
    }

    property bool updateBannerClosed: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // A new version: shown until closed, the next day again
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bannerRow.implicitHeight + 12
            visible: Updater.state === "available" && !window.updateBannerClosed
            color: Styles.TokenInterface.semantics.primary_default
            RowLayout {
                id: bannerRow
                spacing: 8
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                Label {
                    Layout.fillWidth: true
                    text: "Version " + Updater.latestVersion + " des Trainingsplaners ist verfügbar."
                    color: Styles.TokenInterface.semantics.text_on_primary
                    font.bold: true
                }
                Button {
                    text: Updater.installsItself ? "Aktualisieren" : "Ansehen"
                    onClicked: updateDialog.open()
                }
                IconToolButton {
                    iconName: "x"
                    icon.color: Styles.TokenInterface.semantics.text_on_primary
                    toolTip: "Später"
                    onClicked: window.updateBannerClosed = true
                }
            }
        }

        // The week plan is built at start; the other pages when they are
        // first shown, which halves the work before the window appears
        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex
            // Synchronous: a page asked for right after switching to its tab
            // (the start options, tests) is there
            onCurrentIndexChanged: {
                const loader = children[currentIndex]
                if (loader instanceof Loader)
                    loader.active = true
            }

            Loader {
                id: athletesLoader
                active: false
                sourceComponent: AthletesPage {
                    objectName: "athletesPage"
                    startId: window.athlete
                    onSelectedIdChanged: if (selectedId !== "") window.athlete = selectedId
                    // Follows the others only when shown and without unsaved edits
                    onVisibleChanged: if (visible && !dirty && window.athlete !== "" && selectedId !== window.athlete)
                                          select(window.athlete)
                    onOpenWeekPlan: (athleteId) => {
                        window.athlete = athleteId
                        tabs.currentIndex = window.weekTab
                    }
                }
            }

            WeekPage {
                id: weekPage
                objectName: "weekPage"
                choosesAthlete: false
                onAthleteIdChanged: window.athlete = athleteId
            }

            Loader {
                id: planningLoader
                active: false
                sourceComponent: PlanningPage {
                    objectName: "planningPage"
                    choosesAthlete: false
                    athleteId: window.athlete
                    onAthleteIdChanged: window.athlete = athleteId
                }
            }

            Loader {
                id: analysisLoader
                active: false
                sourceComponent: AnalysisPage {
                    objectName: "analysisPage"
                    choosesAthlete: false
                    athleteId: window.athlete
                    onAthleteIdChanged: window.athlete = athleteId
                }
            }

            Loader {
                id: competitionsLoader
                active: false
                sourceComponent: CompetitionsPage {
                    objectName: "competitionsPage"
                    choosesAthlete: false
                    athleteId: window.athlete
                    onAthleteIdChanged: window.athlete = athleteId
                }
            }
        }
    }

    // The pages built on first showing; null until then
    readonly property AthletesPage athletesPage: athletesLoader.item as AthletesPage
    readonly property PlanningPage planningPage: planningLoader.item as PlanningPage
    readonly property AnalysisPage analysisPage: analysisLoader.item as AnalysisPage
    readonly property CompetitionsPage competitionsPage: competitionsLoader.item as CompetitionsPage

    Binding { target: weekPage; property: "athleteId"; value: window.athlete }
    Binding { target: window.planningPage; property: "athleteId"; value: window.athlete }
    Binding { target: window.analysisPage; property: "athleteId"; value: window.athlete }
    Binding { target: window.competitionsPage; property: "athleteId"; value: window.athlete }

    FileDialog {
        id: importDialog
        title: "Datensicherung importieren"
        nameFilters: ["Datensicherung (*.bak)", "Alle Dateien (*)"]
        onAccepted: importOptions.open()
    }

    AppDialog {
        id: importOptions
        title: "Daten importieren"
        standardButtons: Dialog.Ok | Dialog.Cancel
        ColumnLayout {
            spacing: 8
            Label {
                text: decodeURIComponent(importDialog.selectedFile.toString().replace(/^.*\//, ""))
                font.bold: true
            }
            Label {
                text: "Neuere Einträge im Programm bleiben erhalten."
                color: Styles.TokenInterface.semantics.text_muted
            }
            CheckBox {
                id: ignoreTimestamps
                text: "Zeitstempel nicht berücksichtigen (Datei überschreibt alles)"
            }
        }
        onAccepted: {
            importResult.text = Store.importBak(importDialog.selectedFile, ignoreTimestamps.checked)
            ignoreTimestamps.checked = false
            importResult.open()
            window.chooseDefaultAthlete()
        }
    }

    ExportDialog {
        id: exportDialog
    }

    AppDialog {
        id: importResult
        property alias text: resultLabel.text
        title: "Import abgeschlossen"
        standardButtons: Dialog.Ok
        Label {
            id: resultLabel
        }
    }

    SettingsDialog {
        id: settingsDialog
        objectName: "settingsDialog"
    }

    UpdateDialog {
        id: updateDialog
        objectName: "updateDialog"
    }

    AboutDialog {
        id: aboutDialog
        objectName: "aboutDialog"
        onShowUpdateDetails: updateDialog.open()
    }

    HelpDialog {
        id: helpDialog
    }

    Shortcut {
        sequences: [StandardKey.HelpContents]
        enabled: !helpDialog.visible
        onActivated: helpDialog.open()
    }

    WelcomeDialog {
        id: welcomeDialog
        onImportRequested: importDialog.open()
        onDemoCreated: (athleteId) => {
            window.athlete = athleteId
            tabs.currentIndex = window.weekTab
        }
    }

    AppDialog {
        id: removeDemoConfirm
        title: "Beispieldaten entfernen?"
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: "Die erfundenen Beispiel-Sportler werden mit allen ihren Daten gelöscht." }
        onAccepted: Store.removeDemoData()
    }

    Component.onCompleted: {
        Updater.checkOnStart()
        if (startAthlete !== "")
            athlete = startAthlete
        chooseDefaultAthlete()
        if (startPage === "sportler")
            tabs.currentIndex = athletesTab
        if (startPage === "planung") {
            tabs.currentIndex = planningTab
            planningPage.showTab(startSession)
        }
        if (startPage === "analyse") {
            tabs.currentIndex = analysisTab
            Qt.callLater(analysisPage.show, startSession)
        }
        if (startPage === "wettkaempfe") {
            tabs.currentIndex = competitionsTab
            if (startSession === "grafik")
                competitionsPage.showChart()
        }
        if (startPage === "einstellungen")
            Qt.callLater(settingsDialog.open)
        weekPage.start(startAthlete, startWeek, startPage === "" || startPage === "plan" ? startSession : "")
        if (Store.firstStart && startPage === "")
            Qt.callLater(welcomeDialog.open)
    }
}
