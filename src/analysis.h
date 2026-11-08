#pragma once

#include "planning.h"

#include <QDate>
#include <QList>
#include <QString>

#include <cmath>
#include <limits>

// Training analyses as the old program offered them: per exercise or
// group the weekly figures of a period and their summaries.
namespace Analysis {

enum class Basis { Plan, Actual, Itp };
enum class Reference { Absolute, MazTarget, MazCompetition };

constexpr double none = std::numeric_limits<double>::quiet_NaN();
inline bool has(double v) { return !std::isnan(v); }

struct Params
{
    QString athleteId;
    QDate from;  // Monday
    int weeks = 0;
    Basis basis = Basis::Actual;
    bool groups = false;          // rows K1..K7 instead of exercises
    bool includeCompetitionWeeks = false;
    Reference reference = Reference::Absolute;
    QString mazId;                // for the reference values
};

// One exercise or group over the weeks of a period
struct Row
{
    int key = 0;      // exercise, or -1..-7 for K1..K7
    QString name;
    QList<double> wh, mhg, bw, sg; // per week, none = no value
    // Summaries, as the old program's legend:
    // WH:  total, per week, trend per week
    // MHG: best week, period MHG, trend per week
    // BW:  best, MHG of the 30 heaviest attempts, trend per week
    // SG:  mean set size, mean set size of the 30 heaviest, invalid attempts
    double whTotal = none, whPerWeek = none, whTrend = none;
    double mhgMax = none, mhgPeriod = none, mhgTrend = none;
    double bwMax = none, mhgTop30 = none, bwTrend = none;
    double sgMean = none, sgTop30 = none, failed = none;
    bool percent = false; // MHG/BW values in percent of the reference
};

struct Section
{
    QString title;
    QList<QDate> weeks;
    QList<bool> excluded; // competition weeks left out
    int countedWeeks = 0;
    double sessions = 0;  // training sessions in the counted weeks
    QList<Row> rows;
};

Section section(const Params &p);

// Least-squares slope through the defined values (per index step)
double slope(const QList<double> &values);

// Reps at each weight per week for one exercise: rows by kg (heaviest
// first), columns the weeks; plus totals
struct LoadTable
{
    QList<QDate> weeks;
    QList<int> kg;
    QList<QList<int>> reps; // [kg index][week index]
    QList<int> totals;      // per kg
};
LoadTable loadTable(const QString &athleteId, Variant variant, int exercise, const QDate &from, int weeks);

// Sessions with entries per athlete and week: [athlete][week]
QList<int> sessionCounts(const QString &athleteId, const QDate &from, int weeks, Variant variant);

} // namespace Analysis
