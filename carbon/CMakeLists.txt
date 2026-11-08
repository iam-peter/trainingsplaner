# The "Carbon" Qt Quick Controls style, after the IBM Carbon Design
# System. A style is a QML module whose files are named after the
# controls; what it leaves out comes from the Basic style.
qt_add_library(carbonstyle STATIC)
set_source_files_properties(Tokens.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(carbonstyle
    URI Carbon
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Carbon
    IMPORTS QtQuick.Controls.Basic
    QML_FILES
        Tokens.qml
        FocusRing.qml
        ApplicationWindow.qml
        Button.qml
        CheckBox.qml
        ComboBox.qml
        Dialog.qml
        DialogButtonBox.qml
        Frame.qml
        ItemDelegate.qml
        Label.qml
        Menu.qml
        MenuItem.qml
        MenuSeparator.qml
        Page.qml
        Pane.qml
        Popup.qml
        ProgressBar.qml
        RadioButton.qml
        ScrollBar.qml
        ScrollIndicator.qml
        SpinBox.qml
        Switch.qml
        TabBar.qml
        TabButton.qml
        TextArea.qml
        TextField.qml
        ToolBar.qml
        ToolButton.qml
        ToolSeparator.qml
        ToolTip.qml
    RESOURCES
        images/check.svg
        images/chevron-down.svg
        images/chevron-right.svg
)
target_link_libraries(carbonstyle PRIVATE Qt6::Quick Qt6::QuickControls2)
