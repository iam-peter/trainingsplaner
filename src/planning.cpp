#include "planning.h"

#include "catalog.h"
#include "database.h"

#include <QDateTime>
#include <QRegularExpression>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

#include <cmath>

namespace {

const QString kUser = QStringLiteral("local");

QString iso(const QDate &d)
{
    return d.isValid() ? d.toString(Qt::ISODate) : QString();
}

QVariant isoOrNull(const QDate &d)
{
    return d.isValid() ? QVariant(d.toString(Qt::ISODate)) : QVariant();
}

QDate date(const QVariant &v)
{
    return QDate::fromString(v.toString(), Qt::ISODate);
}

QVariant intOrNull(int v)
{
    return v == 0 ? QVariant() : QVariant(v);
}

bool exec(QSqlQuery &q)
{
    if (q.exec())
        return true;
    qWarning("SQL error: %s", qPrintable(q.lastError().text()));
    return false;
}

} // namespace

namespace Planning {

QString roOwner(const QString &mazId)
{
    return QLatin1Char('#') + mazId;
}

bool isRoOwner(const QString &owner)
{
    return owner.startsWith(QLatin1Char('#'));
}

QList<Maz> mazList()
{
    QList<Maz> list;
    QSqlQuery q;
    if (!q.exec(QStringLiteral("SELECT id, sex, name, short_name, first_monday, last_monday, build_up_monday,"
                               " peak_monday, note FROM macrocycles ORDER BY first_monday DESC, name")))
        return list;
    while (q.next()) {
        Maz m;
        m.id = q.value(0).toString();
        m.sex = sexFromInt(q.value(1).toInt());
        m.name = q.value(2).toString();
        m.shortName = q.value(3).toString();
        m.from = date(q.value(4));
        m.to = date(q.value(5));
        m.buildUp = date(q.value(6));
        m.peakPhase = date(q.value(7));
        m.note = q.value(8).toString();
        list.append(m);
    }
    return list;
}

Maz maz(const QString &id)
{
    for (const Maz &m : mazList()) {
        if (m.id == id)
            return m;
    }
    return Maz();
}

QString saveMaz(const Maz &m)
{
    const QString id = m.id.isEmpty()
                           ? QStringLiteral("maz_") + QString::number(QDateTime::currentMSecsSinceEpoch())
                           : m.id;
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO macrocycles (id, sex, name, short_name, first_monday,"
                             " last_monday, build_up_monday, peak_monday, note, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(int(m.sex));
    q.addBindValue(m.name);
    q.addBindValue(m.shortName);
    q.addBindValue(isoOrNull(m.from));
    q.addBindValue(isoOrNull(m.to));
    q.addBindValue(isoOrNull(m.buildUp));
    q.addBindValue(isoOrNull(m.peakPhase));
    q.addBindValue(m.note);
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(Database::now()));
    return exec(q) ? id : QString();
}

bool removeMaz(const QString &id)
{
    QSqlDatabase d = QSqlDatabase::database();
    d.transaction();
    const QDateTime stamp = Database::now();
    const bool ok = Database::deleteRows(QStringLiteral("macrocycle_athletes"), QStringLiteral("macrocycle_id = ?"), {id}, stamp)
                    && Database::deleteRows(QStringLiteral("week_targets"), QStringLiteral("owner = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("planned_steps"), QStringLiteral("owner = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("weeks"), QStringLiteral("owner = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("macrocycles"), QStringLiteral("id = ?"), {id}, stamp);
    if (!ok) {
        d.rollback();
        return false;
    }
    return d.commit();
}

QList<MazAthlete> mazAthletes(const QString &mazId)
{
    QList<MazAthlete> list;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT m.macrocycle_id, m.athlete_id, m.weight_class, m.target_snatch,"
                             " m.target_clean_jerk, m.competition_snatch, m.competition_clean_jerk, m.note,"
                             " m.selected FROM macrocycle_athletes m LEFT JOIN athletes a ON a.id = m.athlete_id"
                             " WHERE m.macrocycle_id = ?"
                             " ORDER BY a.last_name COLLATE NOCASE, a.first_name COLLATE NOCASE"));
    q.addBindValue(mazId);
    if (!exec(q))
        return list;
    while (q.next()) {
        MazAthlete a;
        a.mazId = q.value(0).toString();
        a.athleteId = q.value(1).toString();
        a.weightClass = q.value(2).toInt();
        a.targetSnatch = q.value(3).toInt();
        a.targetCleanJerk = q.value(4).toInt();
        a.compSnatch = q.value(5).toInt();
        a.compCleanJerk = q.value(6).toInt();
        a.note = q.value(7).toString();
        a.selected = q.value(8).isNull() || q.value(8).toBool();
        list.append(a);
    }
    return list;
}

bool saveMazAthlete(const MazAthlete &a)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO macrocycle_athletes (macrocycle_id, athlete_id, weight_class,"
                             " target_snatch, target_clean_jerk, competition_snatch, competition_clean_jerk,"
                             " selected, note, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(a.mazId);
    q.addBindValue(a.athleteId);
    q.addBindValue(intOrNull(a.weightClass));
    q.addBindValue(intOrNull(a.targetSnatch));
    q.addBindValue(intOrNull(a.targetCleanJerk));
    q.addBindValue(intOrNull(a.compSnatch));
    q.addBindValue(intOrNull(a.compCleanJerk));
    q.addBindValue(a.selected ? 1 : 0);
    q.addBindValue(a.note);
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(Database::now()));
    return exec(q);
}

bool removeMazAthlete(const QString &mazId, const QString &athleteId)
{
    return Database::deleteRows(QStringLiteral("macrocycle_athletes"), QStringLiteral("macrocycle_id = ? AND athlete_id = ?"),
                                {mazId, athleteId}, Database::now());
}

QList<Maz> mazForAthlete(const QString &athleteId)
{
    QList<Maz> list;
    for (const Maz &m : mazList()) {
        for (const MazAthlete &a : mazAthletes(m.id)) {
            if (a.athleteId == athleteId) {
                list.append(m);
                break;
            }
        }
    }
    return list;
}

QList<WeekTarget> targets(const QString &owner, const QDate &fromMonday, const QDate &toMonday)
{
    QList<WeekTarget> list;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, exercise, reps, mean_weight, top_weight, top_weight_reps, top_weight_sets"
                             " FROM week_targets WHERE owner = ? AND variant = 'S' AND monday BETWEEN ? AND ?"
                             " ORDER BY monday, exercise"));
    q.addBindValue(owner);
    q.addBindValue(iso(fromMonday));
    q.addBindValue(iso(toMonday));
    if (!exec(q))
        return list;
    while (q.next()) {
        WeekTarget t;
        t.monday = date(q.value(0));
        t.exercise = q.value(1).toInt();
        t.wh = q.value(2).toInt();
        t.mhg = q.value(3).toInt();
        t.bw = q.value(4).toInt();
        t.bwReps = q.value(5).toInt();
        t.bwSets = q.value(6).toInt();
        list.append(t);
    }
    return list;
}

bool setTarget(const QString &owner, const WeekTarget &t)
{
    if (t.isEmpty()) {
        return Database::deleteRows(QStringLiteral("week_targets"),
                                    QStringLiteral("owner = ? AND monday = ? AND exercise = ? AND variant = 'S'"),
                                    {owner, iso(t.monday), t.exercise}, Database::now());
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO week_targets (owner, monday, exercise, variant, reps, mean_weight,"
                             " top_weight, top_weight_reps, top_weight_sets, changed_by, changed_at) VALUES (?, ?, ?, 'S', ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(owner);
    q.addBindValue(iso(t.monday));
    q.addBindValue(t.exercise);
    q.addBindValue(intOrNull(t.wh));
    q.addBindValue(intOrNull(t.mhg));
    q.addBindValue(intOrNull(t.bw));
    q.addBindValue(intOrNull(t.bwReps));
    q.addBindValue(intOrNull(t.bwSets));
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(Database::now()));
    return exec(q);
}

QList<WeekMeta> meta(const QString &owner, const QDate &fromMonday, const QDate &toMonday)
{
    QList<WeekMeta> list;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, load, competition_position, target_note FROM weeks"
                             " WHERE owner = ? AND monday BETWEEN ? AND ? ORDER BY monday"));
    q.addBindValue(owner);
    q.addBindValue(iso(fromMonday));
    q.addBindValue(iso(toMonday));
    if (!exec(q))
        return list;
    while (q.next())
        list.append({date(q.value(0)), q.value(1).toInt(), q.value(2).toString(), q.value(3).toString()});
    return list;
}

bool setMeta(const QString &owner, const WeekMeta &m)
{
    QSqlQuery ins;
    ins.prepare(QStringLiteral("INSERT OR IGNORE INTO weeks (owner, monday) VALUES (?, ?)"));
    ins.addBindValue(owner);
    ins.addBindValue(iso(m.monday));
    QSqlQuery upd;
    upd.prepare(QStringLiteral("UPDATE weeks SET load = ?, competition_position = ?, target_note = ?, changed_by = ?,"
                               " changed_at = ? WHERE owner = ? AND monday = ?"));
    upd.addBindValue(intOrNull(m.load));
    upd.addBindValue(m.position);
    upd.addBindValue(m.note);
    upd.addBindValue(kUser);
    upd.addBindValue(Database::stampText(Database::now()));
    upd.addBindValue(owner);
    upd.addBindValue(iso(m.monday));
    return exec(ins) && exec(upd);
}

QMap<QDate, QList<Step>> plannedSteps(const QString &owner, int exercise, const QDate &fromMonday,
                                      const QDate &toMonday)
{
    QMap<QDate, QList<Step>> map;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, steps FROM planned_steps WHERE owner = ? AND exercise = ?"
                             " AND monday BETWEEN ? AND ?"));
    q.addBindValue(owner);
    q.addBindValue(exercise);
    q.addBindValue(iso(fromMonday));
    q.addBindValue(iso(toMonday));
    if (!exec(q))
        return map;
    while (q.next())
        map.insert(date(q.value(0)), Steps::parse(q.value(1).toString()));
    return map;
}

bool setPlannedSteps(const QString &owner, int exercise, const QDate &monday, const QList<Step> &steps)
{
    if (steps.isEmpty()) {
        return Database::deleteRows(QStringLiteral("planned_steps"), QStringLiteral("owner = ? AND monday = ? AND exercise = ?"),
                                    {owner, iso(monday), exercise}, Database::now());
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO planned_steps (owner, monday, exercise, steps, changed_by, changed_at)"
                             " VALUES (?, ?, ?, ?, ?, ?)"));
    q.addBindValue(owner);
    q.addBindValue(iso(monday));
    q.addBindValue(exercise);
    q.addBindValue(Steps::format(steps));
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(Database::now()));
    return exec(q);
}

bool copyPlan(const QString &fromOwner, const QDate &fromMonday, const QString &toOwner,
              const QDate &toMonday, int weeks)
{
    if (weeks <= 0)
        return true;
    const QDate fromEnd = fromMonday.addDays(7 * (weeks - 1));
    const QDate toEnd = toMonday.addDays(7 * (weeks - 1));
    const qint64 offset = fromMonday.daysTo(toMonday);
    QSqlDatabase d = QSqlDatabase::database();
    d.transaction();
    const QDateTime stamp = Database::now();
    bool ok = Database::deleteRows(QStringLiteral("week_targets"),
                                   QStringLiteral("owner = ? AND variant = 'S' AND monday BETWEEN ? AND ?"),
                                   {toOwner, iso(toMonday), iso(toEnd)}, stamp)
              && Database::deleteRows(QStringLiteral("planned_steps"), QStringLiteral("owner = ? AND monday BETWEEN ? AND ?"),
                                      {toOwner, iso(toMonday), iso(toEnd)}, stamp);
    for (WeekTarget t : targets(fromOwner, fromMonday, fromEnd)) {
        t.monday = t.monday.addDays(offset);
        ok = ok && setTarget(toOwner, t);
    }
    for (WeekMeta m : meta(fromOwner, fromMonday, fromEnd)) {
        m.monday = m.monday.addDays(offset);
        ok = ok && setMeta(toOwner, m);
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, exercise, steps FROM planned_steps WHERE owner = ? AND monday BETWEEN ? AND ?"));
    q.addBindValue(fromOwner);
    q.addBindValue(iso(fromMonday));
    q.addBindValue(iso(fromEnd));
    ok = ok && exec(q);
    while (ok && q.next())
        ok = setPlannedSteps(toOwner, q.value(1).toInt(), date(q.value(0)).addDays(offset),
                             Steps::parse(q.value(2).toString()));
    if (!ok) {
        d.rollback();
        return false;
    }
    return d.commit();
}

int roundToStep(double kg, double step)
{
    if (step <= 0)
        step = 1;
    return int(std::floor(std::round(kg / step) * step + 1e-9));
}

// The target a percentage of the framework plan refers to. As the BVDG
// sets it (Rahmentrainingskonzeption 2019, p. 57): exercises with a wide
// grip refer to the snatch target, those with a narrow grip and the squats
// to the clean & jerk target, which the catalogue's lift says. Complexes
// (negative numbers) take the mean of both: not confirmed yet.
int targetFor(const MazAthlete &a, int exercise)
{
    if (exercise < 0)
        return (a.targetSnatch + a.targetCleanJerk) / 2;
    const Exercise *e = Catalog::find(exercise);
    if (e && e->lift == Exercise::Snatch)
        return a.targetSnatch;
    return a.targetCleanJerk;
}

bool itpFromRo(const QString &mazId, const QString &athleteId, double weightStep)
{
    const Maz m = maz(mazId);
    if (!m.from.isValid())
        return false;
    MazAthlete athlete;
    bool found = false;
    for (const MazAthlete &a : mazAthletes(mazId)) {
        if (a.athleteId == athleteId) {
            athlete = a;
            found = true;
        }
    }
    if (!found)
        return false;

    // The structure first (weeks, load, steps in percent), then convert
    if (!copyPlan(roOwner(mazId), m.from, athleteId, m.from, m.weeks()))
        return false;
    QSqlDatabase d = QSqlDatabase::database();
    d.transaction();
    bool ok = true;
    for (WeekTarget t : targets(athleteId, m.from, m.to)) {
        const int target = targetFor(athlete, t.exercise);
        t.mhg = t.mhg > 0 ? roundToStep(t.mhg * target / 100.0, weightStep) : 0;
        t.bw = t.bw > 0 ? roundToStep(t.bw * target / 100.0, weightStep) : 0;
        ok = ok && setTarget(athleteId, t);
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, exercise, steps FROM planned_steps WHERE owner = ? AND monday BETWEEN ? AND ?"));
    q.addBindValue(athleteId);
    q.addBindValue(iso(m.from));
    q.addBindValue(iso(m.to));
    ok = ok && exec(q);
    QList<QPair<QPair<QDate, int>, QList<Step>>> converted;
    while (ok && q.next()) {
        const int exercise = q.value(1).toInt();
        const int target = targetFor(athlete, exercise);
        QList<Step> steps = Steps::parse(q.value(2).toString());
        for (Step &s : steps)
            s.kg = roundToStep(s.kg * target / 100.0, weightStep);
        converted.append({{date(q.value(0)), exercise}, steps});
    }
    for (const auto &c : std::as_const(converted))
        ok = ok && setPlannedSteps(athleteId, c.first.second, c.first.first, c.second);
    if (!ok) {
        d.rollback();
        return false;
    }
    return d.commit();
}

QMap<QDate, Stats> actualWeekly(const QString &athleteId, Variant variant, int exercise,
                                const QDate &fromMonday, const QDate &toMonday)
{
    QMap<QDate, QList<Step>> perWeek;
    for (const Database::WeightLine &l : Database::weightLines(athleteId, variant, fromMonday, toMonday)) {
        bool match = l.exercise == exercise;
        if (exercise < 0) {
            const Exercise *e = Catalog::find(l.exercise);
            match = e && e->group == -exercise;
        }
        if (match)
            perWeek[l.monday] += l.steps;
    }
    QMap<QDate, Stats> result;
    for (auto it = perWeek.cbegin(); it != perWeek.cend(); ++it)
        result.insert(it.key(), Steps::compute(it.value()));
    return result;
}

QList<Step> parseStepsText(const QString &text, bool *ok)
{
    QList<Step> steps;
    bool good = true;
    const QStringList parts = text.split(QRegularExpression(QStringLiteral("[\\s;,]+")), Qt::SkipEmptyParts);
    for (const QString &p : parts) {
        const QStringList n = p.split(QLatin1Char('/'));
        Step s;
        bool a = false, b = true, c = true;
        s.kg = n.value(0).toInt(&a);
        s.reps = n.size() > 1 ? n[1].toInt(&b) : 1;
        s.sets = n.size() > 2 ? n[2].toInt(&c) : 1;
        if (!a || !b || !c || n.size() > 3 || s.kg <= 0 || s.kg > 999 || s.reps <= 0 || s.reps > 999
            || s.sets <= 0 || s.sets > 99) {
            good = false;
            continue;
        }
        steps.append(s);
    }
    if (ok)
        *ok = good;
    return steps;
}

QString stepsText(const QList<Step> &steps)
{
    QStringList parts;
    for (const Step &s : steps)
        parts.append(QStringLiteral("%1/%2/%3").arg(s.kg).arg(s.reps).arg(qMax(1, s.sets)));
    return parts.join(QLatin1Char(' '));
}

} // namespace Planning
