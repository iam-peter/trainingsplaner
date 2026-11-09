#include "exerciseweek.h"

#include <QMap>
#include <QSet>

#include <algorithm>

namespace {

using Key = QPair<int, int>;

Session *findSession(Week &week, int day, int number)
{
    for (Session &s : week.sessions) {
        if (s.day == day && s.number == number)
            return &s;
    }
    return nullptr;
}

bool isRowOf(const Entry &e, int exercise)
{
    return e.kind == Entry::Weights && e.exercise == exercise;
}

} // namespace

namespace ExerciseWeek {

QList<ExerciseRow> rows(const Week &week, int exercise)
{
    QList<Session> sessions = week.sessions;
    std::sort(sessions.begin(), sessions.end(), [](const Session &a, const Session &b) {
        return a.day != b.day ? a.day < b.day : a.number < b.number;
    });
    QList<ExerciseRow> result;
    for (const Session &s : sessions) {
        for (int i = 0; i < s.entries.size(); ++i) {
            if (!isRowOf(s.entries[i], exercise))
                continue;
            ExerciseRow r;
            r.origDay = r.day = s.day;
            r.origNumber = r.number = s.number;
            r.origIndex = i;
            r.steps = s.entries[i].steps;
            result.append(r);
        }
    }
    return result;
}

QList<QPair<int, int>> apply(Week &week, int exercise, const QList<ExerciseRow> &edited)
{
    QList<Key> touched;
    auto touch = [&touched](int day, int number) {
        if (!touched.contains(Key{day, number}))
            touched.append(Key{day, number});
    };

    // Every original line goes, unless a row keeps it in place.
    QMap<Key, QSet<int>> remove;
    for (const ExerciseRow &r : rows(week, exercise))
        remove[Key{r.origDay, r.origNumber}].insert(r.origIndex);

    QList<ExerciseRow> append;
    for (const ExerciseRow &r : edited) {
        Session *orig = r.origIndex >= 0 ? findSession(week, r.origDay, r.origNumber) : nullptr;
        const bool known = orig && r.origIndex < orig->entries.size()
                           && isRowOf(orig->entries[r.origIndex], exercise);
        if (known && r.day == r.origDay && r.number == r.origNumber) {
            Entry &e = orig->entries[r.origIndex];
            if (e.steps != r.steps) {
                e.steps = r.steps;
                touch(r.day, r.number);
            }
            remove[Key{r.origDay, r.origNumber}].remove(r.origIndex);
        } else {
            append.append(r); // new, or moved: the old line stays marked for removal
        }
    }

    for (auto it = remove.cbegin(); it != remove.cend(); ++it) {
        if (it.value().isEmpty())
            continue;
        Session *s = findSession(week, it.key().first, it.key().second);
        QList<int> indexes = it.value().values();
        std::sort(indexes.begin(), indexes.end(), std::greater<int>());
        for (int i : indexes)
            s->entries.removeAt(i);
        touch(it.key().first, it.key().second);
    }

    for (const ExerciseRow &r : append) {
        Session *s = findSession(week, r.day, r.number);
        if (!s) {
            Session created;
            created.day = r.day;
            created.number = r.number;
            // The times of another session with the same number this week
            for (const Session &other : std::as_const(week.sessions)) {
                if (other.number == r.number && other.from.isValid()) {
                    created.from = other.from;
                    created.to = other.to;
                    break;
                }
            }
            week.sessions.append(created);
            s = &week.sessions.last();
        }
        Entry e;
        e.kind = Entry::Weights;
        e.exercise = exercise;
        e.steps = r.steps;
        s->entries.append(e);
        touch(r.day, r.number);
    }
    return touched;
}

} // namespace ExerciseWeek
