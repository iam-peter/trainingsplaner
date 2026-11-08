#pragma once

#include <QList>
#include <QString>

// The exercise catalogue ("Trainingsübungen", TÜ).
//
// The numbers, groups and names are the ones the old WinWoTA program used,
// so imported training data keeps its meaning. Groups 1-7 are the weekly
// summary groups K1-K7; 8 and 9 are general strength exercises (AMKT).
struct Exercise
{
    enum Lift { Snatch, CleanAndJerk, General };
    enum Input {
        Weights, // entered as weight steps (kg, reps per set, sets)
        Text     // entered as free text plus an optional total of reps
    };

    int id = 0;
    QString name;
    Lift lift = Snatch;
    int group = 0;
    Input input = Weights;
};

namespace Catalog {

const QList<Exercise> &all();
const Exercise *find(int id);
QString name(int id);
bool isWeightExercise(int id);
// Number of groups shown in the weekly summary (K1..K7).
constexpr int summaryGroups = 7;

} // namespace Catalog
