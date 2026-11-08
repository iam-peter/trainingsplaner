#pragma once

#include <QString>

// Light or dark colours, chosen in the settings or following the system.
namespace ColorScheme {

// "system", "light" or "dark"
QString saved();
void save(const QString &scheme);
// Applies to the whole program at once, also while it runs
void apply(const QString &scheme);

} // namespace ColorScheme
