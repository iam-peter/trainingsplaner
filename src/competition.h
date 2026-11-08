#pragma once

#include <QDate>
#include <QList>
#include <QString>
#include <QStringList>

// A competition result (table wk). Attempts: positive = valid, negative =
// invalid at that weight, 0 = not taken.
struct Competition
{
    QString athleteId;
    QDate date;
    QString time = QStringLiteral("00:00:00");
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
bool remove(const QString &athleteId, const QDate &date, const QString &time);
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

// Reference total (IAT "normen") for sex, age and body weight; 0 if unknown
int norm(int sex, int age, double bodyWeight);

} // namespace Competitions
