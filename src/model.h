#pragma once

#include "steps.h"

#include <QDate>
#include <QList>
#include <QMap>
#include <QRegularExpression>
#include <QString>
#include <QStringList>

struct Athlete
{
    QString id; // stable key, e.g. "muster_erika"
    QString lastName;
    QString firstName;
    int sex = 0; // 0 = male, 1 = female
    QDate born;
    QString address;
    QString phone;

    QString displayName() const { return lastName + QStringLiteral(", ") + firstName; }
    QString fullName() const { return firstName + QLatin1Char(' ') + lastName; }
};

// Which version of a week: the plan or the training that actually happened.
enum class Variant { Plan, Actual };

inline QChar variantCode(Variant v)
{
    return v == Variant::Plan ? QLatin1Char('P') : QLatin1Char('I');
}

// One line of a training session.
struct Entry
{
    enum Kind {
        Weights = 0,     // exercise with weight steps
        ExerciseText = 1, // general exercise described in text, plus total reps
        FreeText = 2     // a note without exercise number
    };

    Kind kind = Weights;
    int exercise = 0;
    QList<Step> steps; // Weights only
    QString text;      // ExerciseText / FreeText
    int totalReps = 0; // ExerciseText only ("WH ges."), 0 = not given
    int combination = 0; // carried over from old data, not used yet

    Stats stats() const { return kind == Weights ? Steps::compute(steps) : Stats{}; }

    // Old storage encoding of the entry content.
    QString encode() const;
    static Entry decode(int kind, int exercise, const QString &data, int combination);
};

struct Session
{
    int day = 1;    // 1 = Monday ... 7 = Sunday
    int number = 1; // 1st, 2nd or 3rd session of the day
    QString from;   // "15:30"
    QString to;
    QString note;
    QList<Entry> entries;
};

// Figures for one exercise over a whole week.
struct ExerciseSummary
{
    int exercise = 0;
    Stats stats;
};

struct GroupSummary
{
    int group = 0;
    Stats stats;
    QList<ExerciseSummary> exercises;
};

struct WeekSummary
{
    Stats groups1to7;
    Stats groups1to5;
    QList<GroupSummary> groups; // K1..K7, always seven items
    QMap<int, Stats> perExercise;
};

struct Week
{
    QString athleteId;
    QDate monday;
    Variant variant = Variant::Plan;
    QList<Session> sessions; // sorted by day, then number
    QString note;
    bool injured = false;

    const Session *session(int day, int number) const;
    WeekSummary summary() const;
};

namespace Weeks {

QDate mondayOf(const QDate &date);
// "46/2026"
QString label(const QDate &monday);
// Accepts "46/2026" or "46 2026"; returns an invalid date when unparsable.
QDate fromLabel(const QString &label);
QString dayName(int day);

} // namespace Weeks

// Inline implementations kept here so the struct header stays self-contained.
#include "catalog.h"

inline QString Entry::encode() const
{
    switch (kind) {
    case Weights:
        return Steps::format(steps);
    case ExerciseText:
        return text + QLatin1Char(';') + (totalReps > 0 ? QString::number(totalReps) : QString());
    case FreeText:
        return text;
    }
    return QString();
}

inline Entry Entry::decode(int kind, int exercise, const QString &data, int combination)
{
    Entry e;
    e.exercise = exercise;
    e.combination = combination;
    switch (kind) {
    case ExerciseText: {
        e.kind = ExerciseText;
        const int sep = data.lastIndexOf(QLatin1Char(';'));
        if (sep < 0) {
            e.text = data;
        } else {
            e.text = data.left(sep);
            e.totalReps = data.mid(sep + 1).trimmed().toInt();
        }
        break;
    }
    case FreeText:
        e.kind = FreeText;
        e.text = data;
        break;
    default:
        e.kind = Weights;
        e.steps = Steps::parse(data);
        break;
    }
    return e;
}

inline const Session *Week::session(int day, int number) const
{
    for (const Session &s : sessions) {
        if (s.day == day && s.number == number)
            return &s;
    }
    return nullptr;
}

inline WeekSummary Week::summary() const
{
    QMap<int, QList<Step>> stepsPerExercise;
    for (const Session &s : sessions) {
        for (const Entry &e : s.entries) {
            if (e.kind == Entry::Weights && e.exercise > 0)
                stepsPerExercise[e.exercise] += e.steps;
        }
    }

    WeekSummary sum;
    QList<Step> all1to7, all1to5;
    QList<QList<Step>> perGroup(Catalog::summaryGroups);
    for (auto it = stepsPerExercise.cbegin(); it != stepsPerExercise.cend(); ++it) {
        sum.perExercise.insert(it.key(), Steps::compute(it.value()));
        const Exercise *ex = Catalog::find(it.key());
        if (!ex || ex->group < 1 || ex->group > Catalog::summaryGroups)
            continue;
        perGroup[ex->group - 1] += it.value();
        all1to7 += it.value();
        if (ex->group <= 5)
            all1to5 += it.value();
    }
    for (int g = 1; g <= Catalog::summaryGroups; ++g) {
        GroupSummary gs;
        gs.group = g;
        gs.stats = Steps::compute(perGroup[g - 1]);
        for (auto it = sum.perExercise.cbegin(); it != sum.perExercise.cend(); ++it) {
            const Exercise *ex = Catalog::find(it.key());
            if (ex && ex->group == g)
                gs.exercises.append({it.key(), it.value()});
        }
        sum.groups.append(gs);
    }
    sum.groups1to7 = Steps::compute(all1to7);
    sum.groups1to5 = Steps::compute(all1to5);
    return sum;
}

namespace Weeks {

inline QDate mondayOf(const QDate &date)
{
    return date.addDays(1 - date.dayOfWeek());
}

inline QString label(const QDate &monday)
{
    int year = 0;
    const int week = monday.weekNumber(&year);
    return QStringLiteral("%1/%2").arg(week).arg(year);
}

inline QDate fromLabel(const QString &text)
{
    const QStringList parts = text.trimmed().split(QRegularExpression(QStringLiteral("[/\\s.-]+")),
                                                   Qt::SkipEmptyParts);
    if (parts.size() != 2)
        return QDate();
    bool okW = false, okY = false;
    const int week = parts[0].toInt(&okW);
    const int year = parts[1].toInt(&okY);
    if (!okW || !okY || week < 1 || week > 53 || year < 1900 || year > 2200)
        return QDate();
    // ISO week 1 is the week containing 4 January.
    const QDate monday = mondayOf(QDate(year, 1, 4)).addDays(7 * (week - 1));
    int checkYear = 0;
    if (monday.weekNumber(&checkYear) != week || checkYear != year)
        return QDate();
    return monday;
}

inline QString dayName(int day)
{
    static const char *names[] = {"Montag", "Dienstag", "Mittwoch", "Donnerstag",
                                  "Freitag", "Sonnabend", "Sonntag"};
    if (day < 1 || day > 7)
        return QString();
    return QString::fromLatin1(names[day - 1]);
}

} // namespace Weeks
