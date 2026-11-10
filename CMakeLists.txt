cmake_minimum_required(VERSION 3.21)

project(Trainingsplaner VERSION 0.3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core Gui Widgets Sql Svg Quick QuickControls2 PrintSupport Network Test QuickTest)

qt_standard_project_setup(REQUIRES 6.8)

# Everything that is not UI lives in a static library so the tests can
# link against it without QML.
add_library(tpcore STATIC
    src/catalog.cpp     src/catalog.h
    src/steps.cpp       src/steps.h
    src/model.h
    src/database.cpp    src/database.h
    src/tables.cpp      src/tables.h
    src/bakexport.cpp   src/bakexport.h
    src/exerciseweek.cpp src/exerciseweek.h
    src/competition.cpp src/competition.h
    src/planning.cpp    src/planning.h
    src/analysis.cpp    src/analysis.h
    src/bakimport.cpp   src/bakimport.h
    src/weekreport.cpp  src/weekreport.h
    src/report.cpp      src/report.h
    src/demo.cpp        src/demo.h
    src/update.cpp      src/update.h
)
target_include_directories(tpcore PUBLIC src)
# The database layout
qt_add_resources(tpcore "sql" PREFIX "/" FILES sql/schema.sql)
target_link_libraries(tpcore PUBLIC Qt6::Core Qt6::Gui Qt6::Sql)

# Fonts (Inter, JetBrains Mono) and Lucide icons go into the resources.
file(GLOB TP_FONTS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS fonts/*.ttf)
file(GLOB TP_ICONS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS icons/*.svg)

# The QML module (UI and the Store singleton) as a static library, so the
# QML tests can load the same module as the application.
set_source_files_properties(qml/DialogStack.qml qml/Theme.qml qml/Glossary.qml qml/CellStyle.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
add_subdirectory(style)

qt_add_library(tpqml STATIC)
qt_add_qml_module(tpqml
    URI Trainingsplaner
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Trainingsplaner
    SOURCES
        src/store.cpp src/store.h
        src/planstore.cpp src/planstore.h
        src/itpmodel.cpp src/itpmodel.h
        src/analysisapi.cpp src/analysisapi.h
        src/reportmodel.cpp src/reportmodel.h
        src/updater.cpp src/updater.h
        src/colorscheme.cpp src/colorscheme.h
    QML_FILES
        qml/Main.qml
        qml/KeyMenuItem.qml
        qml/Glossary.qml
        qml/HelpDialog.qml
        qml/WelcomeDialog.qml
        qml/UpdateDialog.qml
        qml/AboutDialog.qml
        qml/AppTabBar.qml
        qml/AppTabButton.qml
        qml/AppToolBar.qml
        qml/Panel.qml
        qml/FormPanel.qml
        qml/DialogScroll.qml
        qml/FieldButton.qml
        qml/ListRow.qml
        qml/ListPanel.qml
        qml/AppScrollBar.qml
        qml/DateCalendar.qml
        qml/DateField.qml
        qml/TimePicker.qml
        qml/TimeField.qml
        qml/WeekField.qml
        qml/ValueComboBox.qml
        qml/SearchField.qml
        qml/WeekPage.qml
        qml/SessionCell.qml
        qml/SessionDialog.qml
        qml/EntryEditor.qml
        qml/ExercisePicker.qml
        qml/AthletesPage.qml
        qml/SettingsDialog.qml
        qml/IconButton.qml
        qml/IconToolButton.qml
        qml/StepsEditor.qml
        qml/ExerciseWeekDialog.qml
        qml/ExerciseRowEditor.qml
        qml/ExportDialog.qml
        qml/AttributeHistoryDialog.qml
        qml/DayInfoDialog.qml
        qml/TrendChart.qml
        qml/ExerciseHistoryDialog.qml
        qml/AttemptField.qml
        qml/CompetitionsPage.qml
        qml/MazPane.qml
        qml/ItpGrid.qml
        qml/PlanningPage.qml
        qml/ReportView.qml
        qml/AnalysisPage.qml
        qml/WeekCalendar.qml
        qml/AppDialog.qml
        qml/DialogButtons.qml
        qml/EditorDialog.qml
        qml/DialogStack.qml
        qml/Theme.qml
        qml/CellStyle.qml
    RESOURCES
        logo/trainingsplaner.svg
        ${TP_FONTS}
        ${TP_ICONS}
)
target_link_libraries(tpqml PUBLIC
    tpstyle
    tpstyleplugin
    tpcore
    Qt6::Network
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::PrintSupport
    # Not called directly: linking it makes the deploy tools bring the SVG
    # image plugin the icons need.
    Qt6::Svg
)

qt_add_executable(trainingsplaner WIN32 MACOSX_BUNDLE
    src/main.cpp
)
target_compile_definitions(trainingsplaner PRIVATE
    PROJECT_VERSION_STRING="${PROJECT_VERSION}")
target_link_libraries(trainingsplaner PRIVATE tpqml tpqmlplugin)
# The icon the file manager, taskbar and Dock show.
set_target_properties(trainingsplaner PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME Trainingsplaner
    MACOSX_BUNDLE_GUI_IDENTIFIER io.github.iam-peter.trainingsplaner
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE_ICON_FILE trainingsplaner.icns
)
if(WIN32)
    target_sources(trainingsplaner PRIVATE logo/trainingsplaner.rc)
elseif(APPLE)
    target_sources(trainingsplaner PRIVATE logo/trainingsplaner.icns)
    set_source_files_properties(logo/trainingsplaner.icns PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources)
endif()

enable_testing()
# Every test run also writes its results to build/test-results, which
# the nightly uploads when a run fails
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/test-results)

qt_add_executable(tst_core tests/tst_core.cpp)
target_link_libraries(tst_core PRIVATE tpcore Qt6::Test)
add_test(NAME tst_core COMMAND tst_core -o ${CMAKE_BINARY_DIR}/test-results/tst_core.txt,txt -o -,txt)
set_tests_properties(tst_core PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

qt_add_executable(tst_qml tests/tst_qml.cpp)
# Console programs: qt_standard_project_setup makes GUI programs on
# Windows, which print nothing, so a failing test left an empty log
set_target_properties(tst_core tst_qml PROPERTIES WIN32_EXECUTABLE FALSE MACOSX_BUNDLE FALSE)
target_compile_definitions(tst_qml PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests")
target_link_libraries(tst_qml PRIVATE tpqml tpqmlplugin Qt6::QuickTest)
# The QML tests, in the program's style (tst_qml.cpp sets it)
add_test(NAME tst_qml COMMAND tst_qml -o ${CMAKE_BINARY_DIR}/test-results/tst_qml.txt,txt -o -,txt)
set_tests_properties(tst_qml PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

include(GNUInstallDirs)
install(TARGETS trainingsplaner
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
if(UNIX AND NOT APPLE)
    # Desktop environments find the icon by the desktop file's Icon= name.
    install(FILES logo/trainingsplaner.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES logo/trainingsplaner.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
endif()

qt_generate_deploy_qml_app_script(
    TARGET trainingsplaner
    OUTPUT_SCRIPT deploy_script
)
install(SCRIPT ${deploy_script})
