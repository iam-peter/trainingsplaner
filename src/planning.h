#pragma once

#include "model.h"

#include <QDate>
#include <QList>
#include <QMap>
#include <QString>

// Long-term planning: macrocycles (MAZ) with their athletes, the framework
// plan of a MAZ (Rahmenorientierung, RO) and the individual training plan
// of an athlete (ITP).
//
// RO and ITP share their storage: week targets per exercise in table
// week_targets (variant "S") and planned weight steps in table
// planned_steps. The owner is the
// athlete id for an ITP and "#" + MAZ id for a RO. In a RO, MHG and BW (and
// the kg of weight steps) are percent of the athlete's target performance.
// Exercise numbers -1..-7 stand for the groups K1..K7.

struct Maz
{
    QString id;
    Sex sex = Sex::Male;
    QString name;
    QString shortName;
    QDate from;       // Monday
    QDate to;         // Monday of the last week
    QDate buildUp;    // start of the build-up phase (Aufbauphase)
    QDate peakPhase;  // start of the performance phase (Leistungsausprägung)
    QString note;

    int weeks() const { return from.isValid() && to.isValid() ? int(from.daysTo(to) / 7) + 1 : 0; }
};

struct MazAthlete
{
    QString mazId;
    QString athleteId;
    int weightClass = 0;
    int targetSnatch = 0;
    int targetCleanJerk = 0;
    int compSnatch = 0;    // result at the MAZ's main competition
    int compCleanJerk = 0;
    bool selected = true; // auswahl; kept from imported data, not shown yet
    QString note;
};

struct WeekTarget
{
    QDate monday;
    int exercise = 0; // > 0 exercise, -1..-7 group K1..K7
    int wh = 0;
    int mhg = 0;
    int bw = 0;
    int bwReps = 0;
    int bwSets = 0;

    bool isEmpty() const { return wh == 0 && mhg == 0 && bw == 0; }
};

struct WeekMeta
{
    QDate monday;
    int load = 0;      // Belastung
    QString position;  // WK-Lage
    QString note;      // bem_soll
};

namespace Planning {

QString roOwner(const QString &mazId);
bool isRoOwner(const QString &owner);

// MAZ
QList<Maz> mazList(); // newest first
Maz maz(const QString &id);
QString saveMaz(const Maz &m); // returns the id (new id if empty)
bool removeMaz(const QString &id);
QList<MazAthlete> mazAthletes(const QString &mazId);
bool saveMazAthlete(const MazAthlete &a);
bool removeMazAthlete(const QString &mazId, const QString &athleteId);
QList<Maz> mazForAthlete(const QString &athleteId);

// Week targets and meta
QList<WeekTarget> targets(const QString &owner, const QDate &fromMonday, const QDate &toMonday);
bool setTarget(const QString &owner, const WeekTarget &t); // empty target: removed
QList<WeekMeta> meta(const QString &owner, const QDate &fromMonday, const QDate &toMonday);
bool setMeta(const QString &owner, const WeekMeta &m);

// Planned weight steps
QMap<QDate, QList<Step>> plannedSteps(const QString &owner, int exercise, const QDate &fromMonday,
                                      const QDate &toMonday);
bool setPlannedSteps(const QString &owner, int exercise, const QDate &monday, const QList<Step> &steps);

// Copies targets, meta and steps of `weeks` weeks, replacing the target range.
bool copyPlan(const QString &fromOwner, const QDate &fromMonday, const QString &toOwner,
              const QDate &toMonday, int weeks);

// The load of a week (Belastung) as a letter: h (hoch) 3, m (mittel) 2,
// g (gesenkt) 1, "" for none, other numbers as they are. WinWoTA keeps
// a small number (TINYINT "bel"); which number it uses for which letter
// is still to be checked on the old program, so the mapping is here only.
QString loadText(int load);
// "h", "m", "g" (either case) or a number; -1 when it is neither
int loadFromText(const QString &text);

// Rounds kg to the weight step as whole kg (2.5: 100, 102, 105, 107 ...)
int roundToStep(double kg, double step);
// The target performance an exercise's percentages refer to
int targetFor(const MazAthlete &a, int exercise);
// ITP of an athlete from the RO of a MAZ: percentages to kg with the
// athlete's targets, rounded to the weight step. Replaces the athlete's
// plan in the MAZ weeks.
bool itpFromRo(const QString &mazId, const QString &athleteId, double weightStep);

// Actual weekly figures of an exercise or group (-1..-7) from the week plans
QMap<QDate, Stats> actualWeekly(const QString &athleteId, Variant variant, int exercise,
                                const QDate &fromMonday, const QDate &toMonday);

// "80/3/2 85/3" <-> steps
QList<Step> parseStepsText(const QString &text, bool *ok = nullptr);
QString stepsText(const QList<Step> &steps);

} // namespace Planning
