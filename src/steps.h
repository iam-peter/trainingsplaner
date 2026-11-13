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

// The next weight up (direction > 0) or down from `kg` in steps of `step`
// kg, as whole kg: with 2.5 that is 100, 102, 105, 107, 110 ...
int nextWeight(int kg, double step, int direction);

// The jump an athlete usually makes from one weight step to the next: the
// most frequent rise between neighbouring steps of the given lines, the
// smaller one on a tie; 0 when no line has two rising steps. Weights on
// a 2.5 kg grid are stored as whole kg (70, 72, 75, 77), so their rises
// alternate 2 and 3 (or 7 and 8): seen both, they count as 2.5 (7.5).
double usualJump(const QList<QList<Step>> &lines);

// The weight proposed after kg with that jump, on the 2.5 kg grid when
// kg is one of its rounded halves (72 for 72.5): 72 + 2.5 gives 75
int proposedWeight(int kg, double jump);

} // namespace Steps
