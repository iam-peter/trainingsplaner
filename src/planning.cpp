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
    if (!q.exec(QStringLiteral("SELECT id, sex, bez, kbez, von, bis, abp_von, lap_von, bem FROM maz"
                               " ORDER BY von DESC, bez")))
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
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO maz (id, sex, bez, kbez, von, bis, abp_von, lap_von, bem,"
                             " user, korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
    const bool ok = Database::deleteRows(QStringLiteral("maz_sp"), QStringLiteral("mazid = ?"), {id}, stamp)
                    && Database::deleteRows(QStringLiteral("ueb"), QStringLiteral("spid = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("itp_ls"), QStringLiteral("spid = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("wo"), QStringLiteral("spid = ?"), {roOwner(id)}, stamp)
                    && Database::deleteRows(QStringLiteral("maz"), QStringLiteral("id = ?"), {id}, stamp);
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
    q.prepare(QStringLiteral("SELECT m.mazid, m.spid, m.gew, m.ziel_rei, m.ziel_sto, m.wk_rei, m.wk_sto, m.bem,"
                             " m.auswahl"
                             " FROM maz_sp m LEFT JOIN sp s ON s.spid = m.spid WHERE m.mazid = ?"
                             " ORDER BY s.name COLLATE NOCASE, s.vorname COLLATE NOCASE"));
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
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO maz_sp (mazid, spid, gew, ziel_rei, ziel_sto, wk_rei, wk_sto,"
                             " auswahl, bem, user, korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
    return Database::deleteRows(QStringLiteral("maz_sp"), QStringLiteral("mazid = ? AND spid = ?"),
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
    q.prepare(QStringLiteral("SELECT wodate, ueb, wh, mhg, bw, bwsg, bwsganz FROM ueb WHERE spid = ? AND spi = 'S'"
                             " AND wodate BETWEEN ? AND ? ORDER BY wodate, ueb"));
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
        return Database::deleteRows(QStringLiteral("ueb"),
                                    QStringLiteral("spid = ? AND wodate = ? AND ueb = ? AND spi = 'S'"),
                                    {owner, iso(t.monday), t.exercise}, Database::now());
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO ueb (spid, wodate, ueb, spi, wh, mhg, bw, bwsg, bwsganz,"
                             " user, korrektur) VALUES (?, ?, ?, 'S', ?, ?, ?, ?, ?, ?, ?)"));
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
    q.prepare(QStringLiteral("SELECT wodate, bel, wklg, bem_soll FROM wo WHERE spid = ? AND wodate BETWEEN ? AND ?"
                             " ORDER BY wodate"));
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
    ins.prepare(QStringLiteral("INSERT OR IGNORE INTO wo (spid, wodate) VALUES (?, ?)"));
    ins.addBindValue(owner);
    ins.addBindValue(iso(m.monday));
    QSqlQuery upd;
    upd.prepare(QStringLiteral("UPDATE wo SET bel = ?, wklg = ?, bem_soll = ?, user = ?, korrektur = ?"
                               " WHERE spid = ? AND wodate = ?"));
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
    q.prepare(QStringLiteral("SELECT wodate, lststbem FROM itp_ls WHERE spid = ? AND ueb = ?"
                             " AND wodate BETWEEN ? AND ?"));
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
        return Database::deleteRows(QStringLiteral("itp_ls"), QStringLiteral("spid = ? AND wodate = ? AND ueb = ?"),
                                    {owner, iso(monday), exercise}, Database::now());
    }
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO itp_ls (spid, wodate, ueb, lststbem, user, korrektur)"
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
    bool ok = Database::deleteRows(QStringLiteral("ueb"), QStringLiteral("spid = ? AND spi = 'S' AND wodate BETWEEN ? AND ?"),
                                   {toOwner, iso(toMonday), iso(toEnd)}, stamp)
              && Database::deleteRows(QStringLiteral("itp_ls"), QStringLiteral("spid = ? AND wodate BETWEEN ? AND ?"),
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
    q.prepare(QStringLiteral("SELECT wodate, ueb, lststbem FROM itp_ls WHERE spid = ? AND wodate BETWEEN ? AND ?"));
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
    q.prepare(QStringLiteral("SELECT wodate, ueb, lststbem FROM itp_ls WHERE spid = ? AND wodate BETWEEN ? AND ?"));
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
