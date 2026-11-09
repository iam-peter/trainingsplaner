#pragma once

#include <QString>

// Light or dark colours, chosen in the settings or following the system,
// or the classic colours of the old program (light).
namespace ColorScheme {

// "system", "light", "dark" or "classic"
QString saved();
void save(const QString &scheme);
// Applies to the whole program at once, also while it runs
void apply(const QString &scheme);
// The scheme last applied (also one given for this start only)
QString active();

} // namespace ColorScheme
