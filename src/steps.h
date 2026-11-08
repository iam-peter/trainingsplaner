#pragma once

#include <QList>
#include <QString>

// One weight step of an exercise: `sets` sets of `reps` repetitions at `kg`.
// `failed` counts invalid attempts (only meaningful for actual training).
struct Step
{
    int kg = 0;
    int reps = 0;
    int sets = 0;
    int failed = 0;

    bool isEmpty() const { return kg == 0 && reps == 0 && sets == 0 && failed == 0; }
    bool operator==(const Step &o) const
    {
        return kg == o.kg && reps == o.reps && sets == o.sets && failed == o.failed;
    }
};

// Load figures as the trainers know them:
//   WH  - total repetitions
//   MHG - mean bar weight (tonnage / WH, rounded)
//   BW  - best (highest) weight, with reps/sets done at it
//   t   - tonnage in kg
struct Stats
{
    int wh = 0;
    double tonnage = 0;
    int mhg = 0;
    int bw = 0;
    int bwReps = 0;
    int bwSets = 0;

    bool isEmpty() const { return wh == 0; }
    QString bwRepsSets() const;
    // "18Wh / 14kg / 0,2t"
    QString summary() const;
};

namespace Steps {

// Old storage format: steps separated by ';', each nine digits
// KKK RRR SS F (kg, reps per set, sets, failed attempts).
QList<Step> parse(const QString &text);
QString format(const QList<Step> &steps);

Stats compute(const QList<Step> &steps);

} // namespace Steps
