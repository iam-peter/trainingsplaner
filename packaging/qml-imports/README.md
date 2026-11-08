# QML imports for deployment

Not part of the program. The deployment tools (windeployqt, macdeployqt,
linuxdeploy-plugin-qt) copy only the QML modules they find imported in
QML files. The styles are loaded by name at runtime, so these files import
them to make the tools ship every style the settings offer: `styles/` on
every system, `windows/` and `macos/` for the native style of that system.
