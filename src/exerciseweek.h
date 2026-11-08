#pragma once

#include "model.h"

#include <QList>
#include <QPair>

// One exercise across a week ("Erfassung TÜ"): every session line with that
// exercise becomes a row that can be edited, moved to another day or
// session, removed, or added.
struct ExerciseRow
{
    // Where the line was when the week was loaded; origIndex is its index in
    // that session's entries, -1 for a row added in the editor.
    int origDay = 0;
    int origNumber = 0;
    int origIndex = -1;

    int day = 1;
    int number = 1;
    QList<Step> steps;
};

namespace ExerciseWeek {

// The rows of `exercise` (weight entries only), ordered by day and session.
QList<ExerciseRow> rows(const Week &week, int exercise);

// Applies the edited rows to `week`: rows missing from `edited` are
// removed, moved rows leave their old session and go to the end of the new
// one, new rows are appended (creating the session when needed). Returns
// the sessions (day, number) that changed.
QList<QPair<int, int>> apply(Week &week, int exercise, const QList<ExerciseRow> &edited);

} // namespace ExerciseWeek
