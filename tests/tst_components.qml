import QtQuick
import QtTest
import Trainingsplaner

// Every QML file of the program compiles and its types resolve, so a
// mistake in a screen the other tests don't open still fails the build.
TestCase {
    name: "Components"

    readonly property var files: [
        "Main", "WeekPage", "SessionCell", "SessionEditor", "EntryEditor", "ExercisePicker",
        "AthletesPage", "SettingsDialog", "IconButton", "IconToolButton", "StepsEditor",
        "ExerciseWeekDialog", "ExerciseRowEditor", "ExportDialog", "AttributeHistoryDialog", "DayInfoDialog", "TrendChart", "ExerciseHistoryDialog", "AttemptField", "CompetitionsPage", "MazPane", "ItpGrid", "PlanningPage", "ReportView", "AnalysisPage", "WeekCalendar", "AppDialog", "DialogStack", "Theme"
    ]

    function test_load_data() {
        return files.map(f => ({ tag: f, file: f }))
    }

    function test_load(data) {
        const c = Qt.createComponent("qrc:/qt/qml/Trainingsplaner/qml/" + data.file + ".qml")
        tryVerify(() => c.status !== Component.Loading)
        compare(c.status, Component.Ready, c.errorString())
    }
}
