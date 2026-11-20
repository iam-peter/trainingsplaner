#pragma once

#include <QDate>
#include <QList>
#include <QString>

// Rules of the German Weightlifting Youth (DGJ) the program uses: its
// Jugendsportprogramm (status June 2025), the IWF's youth weight classes
// from 1 August 2026 and the DM Nachwuchs norms (status August 2026).
// Norms and dates change, so the norms here are only the defaults of an
// editable table.
namespace Youth {

// Age class (AK): the age reached in the competition's year
int ageClass(const QDate &born, const QDate &at);
// Schüler and Jugend, up to AK 17: one competition per week at most
bool limitedToOnePerWeek(int ageClass);

// The youth weight classes (U17) of a sex (0 boys, 1 girls), as their
// upper limits; the class above the last has a "+"
QList<int> weightClassLimits(int sex);
// "-85", "+95": the class of a body weight, "" without one
QString weightClassFor(int sex, double bodyWeight);
// "-85" from 85, "+95" from a limit above the last class
QString weightClassFromLimit(int sex, int limit);

// DM Nachwuchs (AK 14-17): the total to reach between 1 January and the
// entry deadline. AK 14 and AK 15 lift in weight groups, so their norm
// goes by the body weight in whole kg; AK 16 and 17 by the weight class.
struct Norm
{
    int sex = 0;         // 0 boys, 1 girls
    int ageClass = 16;   // 14, 15, or 16 for AK 16 and 17
    QString weightClass; // AK 16-17 "-65", "+95"; AK 14-15 the body weight "46", "+102"
    int total = 0;       // kg
};
// The DGJ's norms, status August 2026
QList<Norm> defaultDmNorms();
// The DM Nachwuchs is for these age classes
bool dmAge(int ageClass);
// The norm table's group of an age class: 14, 15, or 16 for AK 16 and 17
int normGroup(int ageClass);
// The row of the norm table for a body weight: AK 16-17 its weight class,
// AK 14-15 the body weight up to the next whole kg ("46"), the first row
// below the table, "+102" above it; "" without a body weight
QString normRow(int sex, int ageClass, double bodyWeight);

struct Template
{
    QString name;
    int type = 0;  // index into Competitions::typeShortNames(): 0 NT, 1 DM, 2 IT
    QString when;  // the month it usually is in
};
// The national youth competitions of the DGJ's year, to pick from
QList<Template> competitionTemplates();

} // namespace Youth
