#pragma once

class QSettings;

// The program's stored settings across versions
namespace Settings {

// Brings settings written by an older version up to date; runs once.
// Up to version 0.3.0 the default session times and the last export were
// text, now they are a QTime and a QDateTime.
void migrate(QSettings &settings);

} // namespace Settings
