#pragma once

#include "model.h"

#include <QString>

// The BVDG's Kader- und Entwicklungstabelle (KET), Normsystem BVDG 2026
// (Stand 05.12.2025, published 26.01.2026): the total in kg an athlete
// needs for a federal cadre, by cadre, sex, age and weight class. The
// weight classes are those of Youth::weightClassLimits(): the youth's up
// to 17, then the IWF's from 1 August 2026.
namespace Ket {

// Nachwuchskader 1 (ages 15-24 in the table) and Perspektivkader (19-28)
enum Level { NK1, PK };

// The total for an athlete of `age` (competition year minus birth year,
// as the BVDG counts it) and body weight, in the lightest class the body
// weight fits; 0 outside the level's ages or without a body weight.
// For 110+ (men) and 86+ (women) the table gives three totals, the first
// marked Ü1 and the second Ü2, without saying what they mean; this is the
// first.
int norm(Level level, Sex sex, int age, double bodyWeight);

// "KET 2026 NK1 (15–24)"
QString name(Level level);
// The first and last age of a level's table
int firstAge(Level level);
int lastAge(Level level);

} // namespace Ket
