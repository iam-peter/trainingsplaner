# The program's Qt Quick Controls style, the only one it uses. It started
# out after shadcn/ui (https://ui.shadcn.com) and grew its own from there.
# A QML module whose files are named after the controls; what it leaves
# out comes from Basic.
qt_add_library(tpstyle STATIC)
set_source_files_properties(Tokens.qml Primitives.qml TokenInterface.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(tpstyle
    URI TrainingsplanerStyle
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/TrainingsplanerStyle
    IMPORTS QtQuick.Controls.Basic
    QML_FILES
        Primitives.qml
        Semantics.qml
        TokenInterface.qml
        Tokens.qml
        Shadow.qml
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
target_link_libraries(tpstyle PRIVATE Qt6::Quick Qt6::QuickControls2)
