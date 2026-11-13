#pragma once

#include <QDate>
#include <QList>
#include <QString>

// Rules of the German Weightlifting Youth (DGJ) the program uses, from its
// Jugendsportprogramm (status 15 January 2020). Norms and dates change, so
// the norms here are only the defaults of an editable table.
namespace Youth {

// Age class (AK): the age reached in the competition's year
int ageClass(const QDate &born, const QDate &at);
// Schüler and Jugend, up to AK 17: one competition per week at most
bool limitedToOnePerWeek(int ageClass);

// The youth weight classes (Jugend, AK 15-17) of a sex (0 boys, 1 girls),
// as their upper limits; the class above the last has a "+"
QList<int> weightClassLimits(int sex);
// "-89", "+102": the class of a body weight, "" without one
QString weightClassFor(int sex, double bodyWeight);
// "-89" from 89, "+102" from a limit above the last class
QString weightClassFromLimit(int sex, int limit);

struct Norm
{
    int sex = 0;         // 0 boys, 1 girls
    QString weightClass; // "-89", "+102"
    int total = 0;       // kg
};
// DM Jugend (AK 16-17): the total to reach between 1 January and the entry
// deadline, per weight class (DGJ, January 2020)
QList<Norm> defaultDmNorms();
// The DM Jugend is for these age classes
bool dmJugendAge(int ageClass);

struct Template
{
    QString name;
    int type = 0;  // index into Competitions::typeShortNames(): 0 NT, 1 DM, 2 IT
    QString when;  // the month it usually is in
};
// The national youth competitions of the DGJ's year, to pick from
QList<Template> competitionTemplates();

} // namespace Youth
