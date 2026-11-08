#include "demo.h"

#include "competition.h"
#include "database.h"
#include "model.h"

#include <QtMath>

namespace {

// One planned line: exercise, then steps as (percent of the reference max,
// reps per set, sets). Squats and pulls go above 100 % of the lift.
struct Line
{
    int exercise;
    bool snatchBased;
    QList<std::array<int, 3>> steps;
};

struct Day
{
    int day;
    int number;
    QString from;
    QList<Line> lines;
    QString text; // general exercise 33 (Klimmzüge) or a free note
    bool freeText = false;
};

const QList<Day> &weekTemplate()
{
    static const QList<Day> days = {
        {1, 2, QStringLiteral("15:30"),
         {{1, true, {{70, 3, 2}, {78, 2, 2}, {83, 1, 3}}},
          {13, true, {{90, 3, 3}, {100, 3, 2}}},
          {19, false, {{100, 3, 2}, {110, 2, 3}}}},
         QStringLiteral("3x8")},
        {3, 2, QStringLiteral("15:30"),
         {{3, false, {{70, 2, 2}, {80, 1, 3}}},
          {14, false, {{90, 3, 3}}},
          {20, false, {{110, 4, 2}, {120, 3, 3}}}},
         QStringLiteral("Dehnen 15 min"), true},
        {5, 2, QStringLiteral("15:30"),
         {{6, true, {{65, 3, 2}, {75, 2, 3}}},
          {10, false, {{68, 2, 2}, {76, 2, 3}}},
          {25, false, {{45, 5, 3}}}},
         QString()},
        {6, 1, QStringLiteral("10:00"),
         {{1, true, {{75, 2, 2}, {85, 1, 3}}},
          {4, false, {{75, 2, 2}, {85, 1, 2}}},
          {19, false, {{105, 2, 3}}}},
         QString()},
    };
    return days;
}

struct Person
{
    QString lastName;
    QString firstName;
    int sex;
    QDate born;
    int snatchMax;
    int cleanJerkMax;
    double bodyWeight;
};

QList<Session> plannedWeek(const Person &p, double load)
{
    QList<Session> sessions;
    for (const Day &d : weekTemplate()) {
        Session s;
        s.day = d.day;
        s.number = d.number;
        s.from = d.from;
        for (const Line &l : d.lines) {
            Entry e;
            e.exercise = l.exercise;
            const int max = l.snatchBased ? p.snatchMax : p.cleanJerkMax;
            for (const auto &st : l.steps)
                e.steps.append({qRound(max * st[0] / 100.0 * load), st[1], st[2], 0});
            s.entries.append(e);
        }
        if (!d.text.isEmpty()) {
            Entry e;
            e.kind = d.freeText ? Entry::FreeText : Entry::ExerciseText;
            e.exercise = d.freeText ? 0 : 33;
            e.text = d.text;
            e.totalReps = d.freeText ? 0 : 24;
            s.entries.append(e);
        }
        sessions.append(s);
    }
    return sessions;
}

// What actually happened: mostly the plan, one failed snatch and one
// top step left out
QList<Session> actualWeek(QList<Session> sessions, int week)
{
    for (Session &s : sessions) {
        for (Entry &e : s.entries) {
            if (e.steps.isEmpty())
                continue;
            if (e.exercise == 1 && s.day == 1)
                e.steps.last().failed = 1;
            if (e.exercise == 20 && week % 2 == 0)
                e.steps.last().sets -= 1;
        }
    }
    return sessions;
}

} // namespace

namespace Demo {

QStringList create(const QDate &today)
{
    const QList<Person> people = {
        {QStringLiteral("Beispiel"), QStringLiteral("Anna"), 1, QDate(2007, 3, 14), 72, 90, 63.4},
        {QStringLiteral("Beispiel"), QStringLiteral("Ben"), 0, QDate(2005, 8, 2), 105, 130, 80.6},
    };
    const QDate monday = Weeks::mondayOf(today);
    const double loads[] = {0.96, 1.0, 1.03, 0.94, 1.0};

    QStringList ids;
    for (const Person &p : people) {
        Athlete a;
        a.lastName = p.lastName;
        a.firstName = p.firstName;
        a.sex = p.sex;
        a.born = p.born;
        const QString id = Database::saveAthlete(a);
        if (id.isEmpty())
            continue;
        ids.append(id);
        Database::setAttribute(id, QStringLiteral("Verein"), QStringLiteral("Beispielverein"),
                               monday.addYears(-2));

        // Three weeks back to one week ahead; past weeks also as actual
        for (int w = -3; w <= 1; ++w) {
            const QDate m = monday.addDays(7 * w);
            const QList<Session> plan = plannedWeek(p, loads[w + 3]);
            Database::replaceSessions(id, m, Variant::Plan, plan);
            if (w < 0)
                Database::replaceSessions(id, m, Variant::Actual, actualWeek(plan, w));
        }
        Database::saveWeekNote(id, monday, Variant::Plan,
                               QStringLiteral("Beispieldaten: frei erfunden, zum Ausprobieren."), false);

        // Two competitions: one about half a year ago, one two months ago
        for (int k = 0; k < 2; ++k) {
            Competition c;
            c.athleteId = id;
            c.date = today.addDays(k == 0 ? -180 : -60);
            c.type = 0;
            c.name = k == 0 ? QStringLiteral("Frühjahrsturnier") : QStringLiteral("Landesoffene Meisterschaft");
            c.place = QStringLiteral("Musterstadt");
            c.bodyWeight = p.bodyWeight + (k == 0 ? 0.8 : 0.0);
            const int s = p.snatchMax - (k == 0 ? 6 : 3), j = p.cleanJerkMax - (k == 0 ? 7 : 3);
            c.snatch[0] = s - 4;
            c.snatch[1] = s;
            c.snatch[2] = -(s + 3);
            c.cleanJerk[0] = j - 5;
            c.cleanJerk[1] = -j;
            c.cleanJerk[2] = j;
            Competitions::save(c);
        }
    }
    return ids;
}

} // namespace Demo
