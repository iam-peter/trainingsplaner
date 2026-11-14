#pragma once

#include <QDate>
#include <QStringList>

struct Maz;

// Invented example data to try the program without own data: two athletes
// with planned and actual weeks around the given day, a few competitions,
// and for each a MAZ around the day with an ITP from the U17 sample plan
// of the BVDG's Rahmentrainingskonzeption 2019, scaled to the athlete.
namespace Demo {

// Returns the ids of the athletes created.
QStringList create(const QDate &today);
// A MAZ of the example data (removed with it)
bool isDemoMaz(const Maz &maz);

} // namespace Demo
