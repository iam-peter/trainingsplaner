#pragma once

#include <QDate>
#include <QStringList>

// Invented example data to try the program without own data: two athletes
// with planned and actual weeks around the given day and a few competitions.
namespace Demo {

// Returns the ids of the athletes created.
QStringList create(const QDate &today);

} // namespace Demo
