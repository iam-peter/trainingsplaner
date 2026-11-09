#pragma once

#include "model.h"

#include <QDate>
#include <QList>
#include <QString>
#include <QStringList>
#include <QTime>

// A competition result (table competitions). Attempts: positive = valid, negative =
// invalid at that weight, 0 = not taken.
struct Competition
{
    QString athleteId;
    QDate date;
    QTime time = QTime(0, 0); // part of the key; midnight: no time given
    int type = 0; // index into Competitions::typeNames()
    QString name;
    QString place;
    double bodyWeight = 0;
    int snatch[3] = {0, 0, 0};
    int cleanJerk[3] = {0, 0, 0};
    QString note;

    int bestSnatch() const;
    int bestCleanJerk() const;
    // Zweikampf: best valid snatch + best valid clean & jerk, 0 if one is missing
    int total() const;
};

namespace Competitions {

const QStringList &typeNames();      // "Nationales Turnier", ...
const QStringList &typeShortNames(); // "NT", "DM", ...

QList<Competition> forAthlete(const QString &athleteId); // newest first
QList<Competition> between(const QString &athleteId, const QDate &from, const QDate &to);
bool save(const Competition &c);
bool remove(const QString &athleteId, const QDate &date, const QTime &time);
// Whether the athlete had a competition in the week starting `monday`
bool inWeek(const QString &athleteId, const QDate &monday);

// Best result per period: 0 every competition, 1 per half year, 2 per year
struct Point
{
    QString label;
    QDate date;
    int total = 0;
    int snatch = 0;
    int cleanJerk = 0;
};
QList<Point> bestResults(const QList<Competition> &list, int period);

// Reference total (IAT norms, table reference_totals) for sex, age and body weight; 0 if unknown
int norm(Sex sex, int age, double bodyWeight);

} // namespace Competitions
