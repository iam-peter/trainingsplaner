#include "demo.h"

#include "competition.h"
#include "database.h"
#include "model.h"
#include "planning.h"

#include <QMap>
#include <QSettings>
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
    QTime from;
    QList<Line> lines;
    QString text; // general exercise 33 (Klimmzüge) or a free note
    bool freeText = false;
};

const QList<Day> &weekTemplate()
{
    static const QList<Day> days = {
        {1, 2, QTime(15, 30),
         {{1, true, {{70, 3, 2}, {78, 2, 2}, {83, 1, 3}}},
          {13, true, {{90, 3, 3}, {100, 3, 2}}},
          {19, false, {{100, 3, 2}, {110, 2, 3}}}},
         QStringLiteral("3x8")},
        {3, 2, QTime(15, 30),
         {{3, false, {{70, 2, 2}, {80, 1, 3}}},
          {14, false, {{90, 3, 3}}},
          {20, false, {{110, 4, 2}, {120, 3, 3}}}},
         QStringLiteral("Dehnen 15 min"), true},
        {5, 2, QTime(15, 30),
         {{6, true, {{65, 3, 2}, {75, 2, 3}}},
          {10, false, {{68, 2, 2}, {76, 2, 3}}},
          {25, false, {{45, 5, 3}}}},
         QString()},
        {6, 1, QTime(10, 0),
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
    Sex sex;
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

// The 13 weeks of the U17 sample plan of the BVDG's Rahmentrainingskonzeption
// 2019 (Anhang IV): the week's load, the snatch's MHG and BW in kg of the
// plan's reference athlete, and WH of K1-7. Scaled to the athlete for the ITP.
struct PlanWeek
{
    char load;
    int mhg;
    int bw;
    int wh17;
};
const PlanWeek kU17[13] = {
    {'m', 65, 70, 336}, {'h', 67, 72, 417}, {'h', 71, 74, 424}, {'g', 73, 77, 307},
    {'h', 74, 80, 411}, {'h', 76, 83, 366}, {'g', 71, 78, 250}, {'h', 79, 88, 318},
    {'h', 81, 90, 289}, {'g', 73, 85, 230}, {'h', 81, 95, 225}, {'m', 83, 97, 183},
    {'g', 84, 100, 156},
};

const QString kMazNote = QStringLiteral("Beispieldaten: frei erfunden, zum Ausprobieren.");

// A MAZ of 13 weeks with today in its ninth week: eight weeks done, the
// main competition in its last. The ITP holds the snatch (1) and K1-7,
// and the weeks before the demo's own sessions get two done sessions
// each, so the Belastungsverlauf has a course to show.
void createMaz(const QString &id, const Person &p, const QDate &monday)
{
    const QDate from = monday.addDays(-7 * 8);
    Maz z;
    z.sex = p.sex;
    z.name = p.sex == Sex::Female ? QStringLiteral("Beispiel-MAZ Frauen") : QStringLiteral("Beispiel-MAZ Männer");
    z.shortName = p.sex == Sex::Female ? QStringLiteral("BF") : QStringLiteral("BM");
    z.from = from;
    z.to = from.addDays(7 * 12);
    z.buildUp = from.addDays(7 * 4);
    z.peakPhase = from.addDays(7 * 9);
    z.note = kMazNote;
    z.id = Planning::saveMaz(z);
    if (z.id.isEmpty())
        return;

    MazAthlete a;
    a.mazId = z.id;
    a.athleteId = id;
    a.weightClass = p.sex == Sex::Female ? 64 : 81;
    a.targetSnatch = p.snatchMax + 4;
    a.targetCleanJerk = p.cleanJerkMax + 4;
    Planning::saveMazAthlete(a);

    // The sample plan's reference athlete snatches 100 kg: its kg are the
    // Rahmenorientierung's percent of the target
    const QString ro = Planning::roOwner(z.id);
    for (int r = 0; r < 13; ++r) {
        const PlanWeek &w = kU17[r];
        const QDate m = from.addDays(7 * r);
        WeekTarget roSnatch;
        roSnatch.monday = m;
        roSnatch.exercise = 1;
        roSnatch.wh = w.load == 'g' ? 12 : 16;
        roSnatch.mhg = w.mhg;
        roSnatch.bw = w.bw;
        Planning::setTarget(ro, roSnatch);
        // WH of K1-7, on the groups as the demo's weeks train them
        // (K1 33, K2 22, K3 24, K5 35, K6 15 of 129)
        static const int shares[7] = {33, 22, 24, 0, 35, 15, 0};
        for (int g = 0; g < 7; ++g) {
            if (shares[g] == 0)
                continue;
            WeekTarget group;
            group.monday = m;
            group.exercise = -(g + 1);
            group.wh = qRound(w.wh17 * 0.38 * shares[g] / 129.0);
            Planning::setTarget(ro, group);
        }
        WeekMeta roMeta;
        roMeta.monday = m;
        roMeta.load = Planning::loadFromText(QString(QLatin1Char(w.load)));
        Planning::setMeta(ro, roMeta);
    }
    // The ITP: what "Vorlage" makes of the RO, on the program's weight step
    const double step = QSettings().value(QStringLiteral("general/weightStep"), 2.5).toDouble() == 1.0 ? 1.0 : 2.5;
    Planning::itpFromRo(z.id, id, step);

    QMap<QDate, WeekTarget> itp;
    for (const WeekTarget &t : Planning::targets(id, z.from, z.to)) {
        if (t.exercise == 1)
            itp.insert(t.monday, t);
    }
    for (int r = 0; r < 13; ++r) {
        const QDate m = from.addDays(7 * r);
        const int mhg = itp.value(m).mhg, bw = itp.value(m).bw;
        // The ITP's weight steps of the snatch: up to the MHG, then the BW
        Planning::setPlannedSteps(id, 1, m, {{mhg - 5, 3, 2, 0}, {mhg, 2, 3, 0}, {bw, 1, 2, 0}});
        // Done before the demo's own weeks (three back to one ahead)
        if (m < monday.addDays(-7 * 3)) {
            static const int offsets[] = {-2, -1, -3, -1, -2};
            const int off = offsets[r % 5];
            const int cj = p.cleanJerkMax;
            Session s1;
            s1.day = 1;
            s1.number = 2;
            s1.from = QTime(15, 30);
            Entry e1;
            e1.exercise = 1;
            e1.steps = {{mhg - 6 + off, 3, 2, 0}, {mhg + off, 2, 3, 0}, {bw + off, 1, 2, 0}};
            Entry e19;
            e19.exercise = 19;
            e19.steps = {{qRound(cj * 0.83), 5, 2, 0}, {qRound(cj * 0.94), 3, 3, 0}};
            s1.entries = {e1, e19};
            Session s3;
            s3.day = 3;
            s3.number = 2;
            s3.from = QTime(15, 30);
            Entry e3;
            e3.exercise = 3;
            e3.steps = {{qRound(cj * 0.78), 2, 3, 0}, {qRound(cj * 0.87), 1, 3, 0}};
            s3.entries = {e3};
            Database::replaceSessions(id, m, Variant::Actual, {s1, s3});
        }
    }

    // Two competitions to come: one next week, the main one in the MAZ's
    // last week, both on a Saturday
    for (int k = 0; k < 2; ++k) {
        Competition c;
        c.athleteId = id;
        c.date = (k == 0 ? monday.addDays(7) : z.to).addDays(5);
        c.type = k;
        c.name = k == 0 ? QStringLiteral("Landesmeisterschaft") : QStringLiteral("Deutsche Meisterschaft");
        c.place = k == 0 ? QStringLiteral("Musterstadt") : QStringLiteral("Berlin");
        Competitions::save(c);
    }
}

} // namespace

namespace Demo {

bool isDemoMaz(const Maz &maz)
{
    return maz.note == kMazNote;
}

QStringList create(const QDate &today)
{
    const QList<Person> people = {
        {QStringLiteral("Beispiel"), QStringLiteral("Anna"), Sex::Female, QDate(2007, 3, 14), 72, 90, 63.4},
        {QStringLiteral("Beispiel"), QStringLiteral("Ben"), Sex::Male, QDate(2005, 8, 2), 105, 130, 80.6},
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
        Database::saveWeekNote(id, monday, Variant::Plan, kMazNote, false);
        createMaz(id, p, monday);

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
