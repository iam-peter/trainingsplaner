#include "database.h"

#include "tables.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

#include <algorithm>

namespace {

QString g_lastError;


const QString kUser = QStringLiteral("local");

QSqlDatabase db()
{
    return QSqlDatabase::database();
}

bool exec(QSqlQuery &q)
{
    if (!q.exec()) {
        g_lastError = q.lastError().text();
        qWarning("SQL error: %s (%s)", qPrintable(g_lastError), qPrintable(q.lastQuery()));
        return false;
    }
    return true;
}

bool execSql(const QString &sql)
{
    QSqlQuery q(db());
    if (!q.exec(sql)) {
        g_lastError = q.lastError().text();
        qWarning("SQL error: %s (%s)", qPrintable(g_lastError), qPrintable(sql));
        return false;
    }
    return true;
}

// The tables' layout (sql/schema.sql); meta.schema says which one a
// database file has. Layout 1 was version 0.3.0's, with German names.
// Raise it with every change to the tables: a file of another layout is
// not opened.
constexpr int kSchemaVersion = 2;

// The statements of an SQL file, without comments, split at the
// semicolons outside of quotes (Qt runs one statement at a time)
QStringList sqlStatements(const QString &text)
{
    QStringList list;
    QString current;
    QChar quote;
    for (qsizetype i = 0; i < text.size(); ++i) {
        const QChar c = text.at(i);
        if (!quote.isNull()) {
            current += c;
            if (c == quote)
                quote = QChar();
        } else if (c == QLatin1Char('\'') || c == QLatin1Char('"')) {
            quote = c;
            current += c;
        } else if (c == QLatin1Char('-') && text.mid(i, 2) == QLatin1String("--")) {
            while (i < text.size() && text.at(i) != QLatin1Char('\n'))
                ++i;
            current += QLatin1Char('\n');
        } else if (c == QLatin1Char(';')) {
            if (!current.trimmed().isEmpty())
                list.append(current.trimmed());
            current.clear();
        } else {
            current += c;
        }
    }
    if (!current.trimmed().isEmpty())
        list.append(current.trimmed());
    return list;
}

// Runs one of the SQL files built into the program (sql/)
bool runSqlFile(const QString &name)
{
    QFile f(QStringLiteral(":/sql/") + name);
    if (!f.open(QIODevice::ReadOnly)) {
        g_lastError = QStringLiteral("%1 fehlt im Programm").arg(name);
        return false;
    }
    for (const QString &sql : sqlStatements(QString::fromUtf8(f.readAll()))) {
        if (!execSql(sql))
            return false;
    }
    return true;
}

int fileSchemaVersion()
{
    QSqlQuery q(db());
    if (!q.exec(QStringLiteral("SELECT value FROM meta WHERE key = 'schema'")) || !q.next())
        return 0;
    return q.value(0).toInt();
}

QString dateString(const QDate &d)
{
    return d.toString(Qt::ISODate);
}

QString variantString(Variant v)
{
    return QString(variantCode(v));
}

QString noteColumn(Variant v)
{
    return v == Variant::Plan ? QStringLiteral("plan_note") : QStringLiteral("actual_note");
}

// A session's start or end; none is NULL (the old program wrote 00:00:00)
QVariant timeToStorage(const QTime &t)
{
    return t.isValid() ? QVariant(Times::stored(t)) : QVariant();
}

QTime timeFromStorage(const QString &t)
{
    const QTime time = Times::parse(t);
    return time == QTime(0, 0) ? QTime() : time;
}

QString makeAthleteId(const QString &last, const QString &first)
{
    QString base = (last.trimmed() + QLatin1Char('_') + first.trimmed()).toLower();
    base.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral("_"));
    base.remove(QLatin1Char('"'));
    if (base == QLatin1String("_"))
        base = QStringLiteral("sportler");
    QString id = base;
    for (int n = 2;; ++n) {
        QSqlQuery q(db());
        q.prepare(QStringLiteral("SELECT 1 FROM athletes WHERE id = ?"));
        q.addBindValue(id);
        if (!exec(q) || !q.next())
            return id;
        id = base + QLatin1Char('_') + QString::number(n);
    }
}

// Deletes rows and notes their keys in the deletion log.
bool deleteLogged(const QString &table, const QString &where, const QVariantList &binds,
                const QDateTime &stamp)
{
    const TableSpec *spec = Tables::find(table);
    if (spec) {
        const QStringList keys = spec->keys();
        QSqlQuery sel(db());
        sel.prepare(QStringLiteral("SELECT %1 FROM %2 WHERE %3")
                        .arg(keys.join(QStringLiteral(", ")), table, where));
        for (const QVariant &b : binds)
            sel.addBindValue(b);
        if (!exec(sel))
            return false;
        while (sel.next()) {
            QVariantList key;
            for (int i = 0; i < keys.size(); ++i)
                key.append(sel.value(i));
            if (!Database::recordDeletion(table, key, stamp))
                return false;
        }
    }
    QSqlQuery del(db());
    del.prepare(QStringLiteral("DELETE FROM %1 WHERE %2").arg(table, where));
    for (const QVariant &b : binds)
        del.addBindValue(b);
    return exec(del);
}

bool insertSession(const QString &athleteId, const QDate &monday, Variant variant,
                   const Session &s, const QDateTime &stamp)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO sessions (athlete_id, monday, day, number, variant, kind, start_time, end_time, note,"
        " changed_by, changed_at)"
        " VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?)"));
    q.addBindValue(athleteId);
    q.addBindValue(dateString(monday));
    q.addBindValue(s.day);
    q.addBindValue(s.number);
    q.addBindValue(variantString(variant));
    q.addBindValue(timeToStorage(s.from));
    q.addBindValue(timeToStorage(s.to));
    q.addBindValue(s.note);
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(stamp));
    if (!exec(q))
        return false;

    // Lines beyond the new count are gone; the others are written again.
    if (!deleteLogged(QStringLiteral("session_entries"),
                    QStringLiteral("athlete_id = ? AND monday = ? AND day = ? AND number = ? AND variant = ? AND position > ?"),
                    {athleteId, dateString(monday), s.day, s.number, variantString(variant),
                     int(s.entries.size())},
                    stamp))
        return false;
    QSqlQuery del(db());
    del.prepare(QStringLiteral(
        "DELETE FROM session_entries WHERE athlete_id = ? AND monday = ? AND day = ? AND number = ? AND variant = ?"));
    del.addBindValue(athleteId);
    del.addBindValue(dateString(monday));
    del.addBindValue(s.day);
    del.addBindValue(s.number);
    del.addBindValue(variantString(variant));
    if (!exec(del))
        return false;

    int pos = 0;
    for (const Entry &e : s.entries) {
        QSqlQuery ins(db());
        ins.prepare(QStringLiteral(
            "INSERT INTO session_entries (athlete_id, monday, day, number, position, variant, exercise,"
            " content, kind, combination, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
        ins.addBindValue(athleteId);
        ins.addBindValue(dateString(monday));
        ins.addBindValue(s.day);
        ins.addBindValue(s.number);
        ins.addBindValue(++pos);
        ins.addBindValue(variantString(variant));
        ins.addBindValue(e.kind == Entry::FreeText ? 0 : e.exercise);
        ins.addBindValue(e.encode());
        ins.addBindValue(int(e.kind));
        ins.addBindValue(e.combination);
        ins.addBindValue(kUser);
        ins.addBindValue(Database::stampText(stamp));
        if (!exec(ins))
            return false;
    }
    return true;
}

} // namespace

namespace Database {

QString lastError()
{
    return g_lastError;
}

int schemaVersion()
{
    return fileSchemaVersion();
}

int latestSchemaVersion()
{
    return kSchemaVersion;
}

QDateTime now()
{
    QDateTime t = QDateTime::currentDateTime();
    t.setTime(QTime(t.time().hour(), t.time().minute(), t.time().second()));
    return t;
}

QString stampText(const QDateTime &time)
{
    return time.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

QDateTime stampTime(const QString &text)
{
    const QString t = text.trimmed();
    QDateTime time = QDateTime::fromString(t, QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    if (!time.isValid())
        time = QDateTime::fromString(t, Qt::ISODate);
    // Stamps are local time; one with Z or an offset is that moment here
    return time.isValid() ? time.toLocalTime() : time;
}

bool open(const QString &path, QString *error, bool existingOnly)
{
    if (existingOnly && !QFileInfo(path).isFile()) {
        if (error)
            *error = QStringLiteral("Die Datei gibt es nicht.");
        return false;
    }
    QDir().mkpath(QFileInfo(path).absolutePath());
    QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    d.setDatabaseName(path);
    if (!d.open()) {
        if (error)
            *error = d.lastError().text();
        return false;
    }
    execSql(QStringLiteral("PRAGMA foreign_keys = ON"));
    // A file of another layout is left alone; a new one has none yet (0)
    const int version = fileSchemaVersion();
    QString failure;
    if (existingOnly && version == 0)
        failure = QStringLiteral("Die Datei ist kein Projekt des Trainingsplaners.");
    else if (version != 0 && version != kSchemaVersion)
        failure = QStringLiteral("Die Datenbank stammt von einer anderen Version des Trainingsplaners.");
    // Missing tables are created, existing ones stay as they are
    else if (!runSqlFile(QStringLiteral("schema.sql")))
        failure = g_lastError;
    if (!failure.isEmpty()) {
        g_lastError = failure;
        if (error)
            *error = failure;
        d = QSqlDatabase();
        close();
        return false;
    }
    return true;
}

void close()
{
    const QString name = QSqlDatabase::database().connectionName();
    QSqlDatabase::database().close();
    QSqlDatabase::removeDatabase(name);
}

QString path()
{
    return db().databaseName();
}

bool copyTo(const QString &path, QString *error)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("VACUUM INTO ?"));
    q.addBindValue(path);
    if (!q.exec()) {
        if (error)
            *error = q.lastError().text();
        return false;
    }
    return true;
}

QList<Athlete> athletes()
{
    QList<Athlete> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral(
        "SELECT id, last_name, first_name, sex, born, address, phone FROM athletes"
        " ORDER BY last_name COLLATE NOCASE, first_name COLLATE NOCASE"));
    if (!exec(q))
        return list;
    while (q.next()) {
        Athlete a;
        a.id = q.value(0).toString();
        a.lastName = q.value(1).toString();
        a.firstName = q.value(2).toString();
        a.sex = sexFromInt(q.value(3).toInt());
        a.born = QDate::fromString(q.value(4).toString(), Qt::ISODate);
        a.address = q.value(5).toString();
        a.phone = q.value(6).toString();
        list.append(a);
    }
    return list;
}

Athlete athlete(const QString &id)
{
    for (const Athlete &a : athletes()) {
        if (a.id == id)
            return a;
    }
    return Athlete();
}

QString saveAthlete(const Athlete &a)
{
    const QString id = a.id.isEmpty() ? makeAthleteId(a.lastName, a.firstName) : a.id;
    QSqlQuery q(db());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO athletes (id, last_name, first_name, sex, born, address, phone,"
        " changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(a.lastName.trimmed());
    q.addBindValue(a.firstName.trimmed());
    q.addBindValue(int(a.sex));
    q.addBindValue(a.born.isValid() ? dateString(a.born) : QVariant());
    q.addBindValue(a.address);
    q.addBindValue(a.phone);
    q.addBindValue(kUser);
    q.addBindValue(stampText(now()));
    return exec(q) ? id : QString();
}

bool removeAthlete(const QString &id)
{
    QSqlDatabase d = db();
    d.transaction();
    const QDateTime stamp = now();
    // Everything of the athlete, then the athlete
    const std::pair<const char *, const char *> owned[] = {
        {"session_entries", "athlete_id"}, {"sessions", "athlete_id"}, {"weeks", "owner"},
        {"athlete_info", "athlete_id"}, {"competitions", "athlete_id"}, {"macrocycle_athletes", "athlete_id"},
        {"week_targets", "owner"}, {"planned_steps", "owner"}, {"athletes", "id"}};
    for (const auto &[table, column] : owned) {
        if (!deleteRows(QLatin1String(table), QStringLiteral("%1 = ?").arg(QLatin1String(column)), {id}, stamp)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

namespace {

QList<InfoRecord> readInfo(QSqlQuery &q)
{
    QList<InfoRecord> list;
    while (q.next()) {
        InfoRecord r;
        r.athleteId = q.value(0).toString();
        r.art = q.value(1).toString();
        r.from = QDate::fromString(q.value(2).toString(), Qt::ISODate);
        r.time = Times::parse(q.value(3).toString());
        r.to = QDate::fromString(q.value(4).toString(), Qt::ISODate);
        r.text = q.value(5).toString();
        r.hasNumber = !q.value(6).isNull();
        r.number = q.value(6).toDouble();
        list.append(r);
    }
    return list;
}

const QString kInfoColumns = QStringLiteral("athlete_id, kind, from_date, time, to_date, text, number");

} // namespace

QList<InfoRecord> infoRecords(const QString &athleteId, const QString &art)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT %1 FROM athlete_info WHERE athlete_id = ? AND kind = ? ORDER BY from_date, time")
                  .arg(kInfoColumns));
    q.addBindValue(athleteId);
    q.addBindValue(art);
    if (!exec(q))
        return {};
    return readInfo(q);
}

QList<InfoRecord> infoRecords(const QStringList &arts)
{
    if (arts.isEmpty())
        return {};
    QStringList marks;
    for (int i = 0; i < arts.size(); ++i)
        marks.append(QStringLiteral("?"));
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT %1 FROM athlete_info WHERE kind IN (%2) ORDER BY athlete_id, kind, from_date, time")
                  .arg(kInfoColumns, marks.join(QLatin1Char(','))));
    for (const QString &a : arts)
        q.addBindValue(a);
    if (!exec(q))
        return {};
    return readInfo(q);
}

QList<InfoRecord> infoRecordsBetween(const QString &athleteId, const QStringList &arts,
                                     const QDate &from, const QDate &to)
{
    if (arts.isEmpty())
        return {};
    QStringList marks;
    for (int i = 0; i < arts.size(); ++i)
        marks.append(QStringLiteral("?"));
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT %1 FROM athlete_info WHERE athlete_id = ? AND kind IN (%2)"
                             " AND from_date BETWEEN ? AND ? ORDER BY from_date, time, kind")
                  .arg(kInfoColumns, marks.join(QLatin1Char(','))));
    q.addBindValue(athleteId);
    for (const QString &a : arts)
        q.addBindValue(a);
    q.addBindValue(from.toString(Qt::ISODate));
    q.addBindValue(to.toString(Qt::ISODate));
    if (!exec(q))
        return {};
    return readInfo(q);
}

bool replaceInfoRecordsBetween(const QString &athleteId, const QStringList &arts,
                               const QDate &from, const QDate &to,
                               const QList<InfoRecord> &records)
{
    QSqlDatabase d = db();
    d.transaction();
    const QDateTime stamp = now();
    const QList<InfoRecord> before = infoRecordsBetween(athleteId, arts, from, to);
    // The same record: same kind, day and time of day (the key)
    const auto same = [](const QList<InfoRecord> &list, const InfoRecord &key) -> const InfoRecord * {
        for (const InfoRecord &r : list) {
            if (r.art == key.art && r.from == key.from && r.time == key.time)
                return &r;
        }
        return nullptr;
    };
    for (const InfoRecord &old : before) {
        if (!same(records, old)
            && !deleteRows(QStringLiteral("athlete_info"),
                           QStringLiteral("athlete_id = ? AND kind = ? AND from_date = ? AND time = ?"),
                           {athleteId, old.art, old.from.toString(Qt::ISODate), Times::stored(old.time)}, stamp)) {
            d.rollback();
            return false;
        }
    }
    for (InfoRecord r : records) {
        r.athleteId = athleteId;
        // Unchanged records are not written again, so an export of the
        // changes since a date leaves them out
        const InfoRecord *old = same(before, r);
        if (old && old->hasNumber == r.hasNumber && old->number == r.number && old->text == r.text
            && old->to == r.to)
            continue;
        if (!saveInfoRecord(r)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

bool saveInfoRecord(const InfoRecord &r)
{
    if (r.athleteId.isEmpty() || r.art.isEmpty() || !r.from.isValid())
        return false;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO athlete_info (athlete_id, kind, from_date, time, to_date,"
                             " text, number, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(r.athleteId);
    q.addBindValue(r.art);
    q.addBindValue(r.from.toString(Qt::ISODate));
    q.addBindValue(Times::stored(r.time));
    q.addBindValue(r.to.isValid() ? QVariant(r.to.toString(Qt::ISODate)) : QVariant());
    q.addBindValue(r.text);
    q.addBindValue(r.hasNumber ? QVariant(r.number) : QVariant());
    q.addBindValue(kUser);
    q.addBindValue(stampText(now()));
    return exec(q);
}

bool removeInfoRecord(const QString &athleteId, const QString &art, const QDate &from,
                      const QTime &time)
{
    return deleteRows(QStringLiteral("athlete_info"), QStringLiteral("athlete_id = ? AND kind = ? AND from_date = ? AND time = ?"),
                      {athleteId, art, from.toString(Qt::ISODate), Times::stored(time)}, now());
}

bool replaceInfoRecords(const QString &athleteId, const QString &art,
                        const QList<InfoRecord> &records)
{
    QSqlDatabase d = db();
    d.transaction();
    const QDateTime stamp = now();
    const QList<InfoRecord> before = infoRecords(athleteId, art);
    // A record is the same one when it starts on the same day; it keeps
    // its stored time of day and number (imported records can have both)
    const auto sameDay = [](const QList<InfoRecord> &list, const QDate &from) {
        const auto it = std::find_if(list.begin(), list.end(), [&](const InfoRecord &r) { return r.from == from; });
        return it == list.end() ? nullptr : &*it;
    };
    for (const InfoRecord &old : before) {
        if (!sameDay(records, old.from)
            && !deleteRows(QStringLiteral("athlete_info"),
                           QStringLiteral("athlete_id = ? AND kind = ? AND from_date = ? AND time = ?"),
                           {athleteId, art, old.from.toString(Qt::ISODate), Times::stored(old.time)}, stamp)) {
            d.rollback();
            return false;
        }
    }
    for (InfoRecord r : records) {
        r.athleteId = athleteId;
        r.art = art;
        if (const InfoRecord *old = sameDay(before, r.from)) {
            // Unchanged records are not written again, so an export of the
            // changes since a date leaves them out
            if (old->to == r.to && old->text == r.text)
                continue;
            r.time = old->time;
            r.number = old->number;
            r.hasNumber = old->hasNumber;
        }
        if (!saveInfoRecord(r)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

QStringList infoValues(const QString &art)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT DISTINCT text FROM athlete_info WHERE kind = ? AND text <> ''"
                             " ORDER BY text COLLATE NOCASE"));
    q.addBindValue(art);
    QStringList list;
    if (exec(q)) {
        while (q.next())
            list.append(q.value(0).toString());
    }
    return list;
}

QList<ExerciseUse> exerciseUses(const QString &athleteId, Variant variant, int exercise,
                                const QDate &fromMonday, const QDate &toMonday)
{
    QList<ExerciseUse> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT monday, day, number, content FROM session_entries WHERE athlete_id = ?"
                             " AND variant = ? AND exercise = ? AND kind = 0 AND monday BETWEEN ? AND ?"
                             " ORDER BY monday, day, number, position"));
    q.addBindValue(athleteId);
    q.addBindValue(variantString(variant));
    q.addBindValue(exercise);
    q.addBindValue(dateString(fromMonday));
    q.addBindValue(dateString(toMonday));
    if (!exec(q))
        return list;
    while (q.next()) {
        ExerciseUse u;
        u.monday = QDate::fromString(q.value(0).toString(), Qt::ISODate);
        u.day = q.value(1).toInt();
        u.number = q.value(2).toInt();
        u.steps = Steps::parse(q.value(3).toString());
        if (!u.steps.isEmpty())
            list.append(u);
    }
    return list;
}

QStringList recentContents(const QString &athleteId, int kind, int exercise, int limit)
{
    QStringList list;
    QSqlQuery q(db());
    const bool ownOnly = kind == 0;
    // The exercise as its own condition, so the index on (kind, exercise)
    // serves it
    q.prepare(QStringLiteral("SELECT content, MAX(athlete_id = ?) AS own, MAX(monday) AS last FROM session_entries"
                             " WHERE kind = ?%1 AND content <> ''%2"
                             " GROUP BY content ORDER BY own DESC, last DESC LIMIT ?")
                  .arg(exercise >= 0 ? QStringLiteral(" AND exercise = ?") : QString(),
                       ownOnly ? QStringLiteral(" AND athlete_id = ?") : QString()));
    q.addBindValue(athleteId);
    q.addBindValue(kind);
    if (exercise >= 0)
        q.addBindValue(exercise);
    if (ownOnly)
        q.addBindValue(athleteId);
    q.addBindValue(limit);
    if (!exec(q))
        return list;
    while (q.next())
        list.append(q.value(0).toString());
    return list;
}

QList<WeightLine> weightLines(const QString &athleteId, Variant variant, const QDate &fromMonday,
                              const QDate &toMonday)
{
    QList<WeightLine> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT monday, day, exercise, content FROM session_entries WHERE athlete_id = ?"
                             " AND variant = ? AND kind = 0 AND exercise > 0 AND monday BETWEEN ? AND ?"
                             " ORDER BY monday, day, number, position"));
    q.addBindValue(athleteId);
    q.addBindValue(variantString(variant));
    q.addBindValue(dateString(fromMonday));
    q.addBindValue(dateString(toMonday));
    if (!exec(q))
        return list;
    while (q.next()) {
        WeightLine l;
        l.monday = QDate::fromString(q.value(0).toString(), Qt::ISODate);
        l.day = q.value(1).toInt();
        l.exercise = q.value(2).toInt();
        l.steps = Steps::parse(q.value(3).toString());
        if (!l.steps.isEmpty())
            list.append(l);
    }
    return list;
}

const InfoRecord *infoAt(const QList<InfoRecord> &records, const QDate &date)
{
    const InfoRecord *found = nullptr;
    for (const InfoRecord &r : records) {
        if (r.from <= date && (!r.to.isValid() || r.to >= date)) {
            if (!found || r.from > found->from)
                found = &r;
        }
    }
    return found;
}

bool setAttribute(const QString &athleteId, const QString &art, const QString &value,
                  const QDate &date)
{
    const QString v = value.trimmed();
    QList<InfoRecord> records = infoRecords(athleteId, art);
    const InfoRecord *current = infoAt(records, date);
    if (current && current->text == v)
        return true;
    if (!current && v.isEmpty())
        return true;

    QSqlDatabase d = db();
    d.transaction();
    bool ok = true;
    QDate end; // the new record ends where the current one ended
    if (current) {
        InfoRecord c = *current;
        end = c.to;
        if (c.from == date) {
            ok = removeInfoRecord(athleteId, art, c.from, c.time);
        } else {
            c.to = date.addDays(-1);
            ok = saveInfoRecord(c);
        }
    } else {
        // Up to the next record, if one starts later
        for (const InfoRecord &r : std::as_const(records)) {
            if (r.from > date && (!end.isValid() || r.from.addDays(-1) < end))
                end = r.from.addDays(-1);
        }
    }
    if (ok && !v.isEmpty()) {
        InfoRecord n;
        n.athleteId = athleteId;
        n.art = art;
        n.from = date;
        n.to = end;
        n.text = v;
        ok = saveInfoRecord(n);
    }
    if (!ok) {
        d.rollback();
        return false;
    }
    return d.commit();
}

bool deleteRows(const QString &table, const QString &where, const QVariantList &binds,
                const QDateTime &stamp)
{
    return deleteLogged(table, where, binds, stamp);
}

bool recordDeletion(const QString &table, const QVariantList &key, const QDateTime &stamp)
{
    QStringList parts;
    for (const QVariant &v : key)
        parts.append(v.toString());
    QSqlQuery q(db());
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO deletions (table_name, row_key, deleted_at)"
                             " VALUES (?, ?, ?)"));
    q.addBindValue(table);
    q.addBindValue(parts.join(QChar(0x1f)));
    q.addBindValue(stampText(stamp));
    return exec(q);
}

QList<Deletion> deletions(const QString &table, const QDateTime &since)
{
    QList<Deletion> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT row_key, deleted_at FROM deletions WHERE table_name = ?%1"
                             " ORDER BY deleted_at")
                  .arg(since.isValid() ? QStringLiteral(" AND deleted_at >= ?") : QString()));
    q.addBindValue(table);
    if (since.isValid())
        q.addBindValue(stampText(since));
    if (!exec(q))
        return list;
    while (q.next())
        list.append({q.value(0).toString().split(QChar(0x1f)), stampTime(q.value(1).toString())});
    return list;
}

int sessionCount(const QString &athleteId)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT COUNT(*) FROM sessions WHERE athlete_id = ?"));
    q.addBindValue(athleteId);
    if (!exec(q) || !q.next())
        return 0;
    return q.value(0).toInt();
}

Week loadWeek(const QString &athleteId, const QDate &monday, Variant variant)
{
    Week w;
    w.athleteId = athleteId;
    w.monday = monday;
    w.variant = variant;

    QMap<QPair<int, int>, Session> sessions;

    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT day, number, start_time, end_time, note FROM sessions"
                             " WHERE athlete_id = ? AND monday = ? AND variant = ?"));
    q.addBindValue(athleteId);
    q.addBindValue(dateString(monday));
    q.addBindValue(variantString(variant));
    if (exec(q)) {
        while (q.next()) {
            Session s;
            s.day = q.value(0).toInt();
            s.number = q.value(1).toInt();
            s.from = timeFromStorage(q.value(2).toString());
            s.to = timeFromStorage(q.value(3).toString());
            s.note = q.value(4).toString();
            sessions.insert({s.day, s.number}, s);
        }
    }

    QSqlQuery e(db());
    e.prepare(QStringLiteral("SELECT day, number, exercise, content, kind, combination FROM session_entries"
                             " WHERE athlete_id = ? AND monday = ? AND variant = ? ORDER BY day, number, position"));
    e.addBindValue(athleteId);
    e.addBindValue(dateString(monday));
    e.addBindValue(variantString(variant));
    if (exec(e)) {
        while (e.next()) {
            const QPair<int, int> key{e.value(0).toInt(), e.value(1).toInt()};
            Session &s = sessions[key];
            s.day = key.first;
            s.number = key.second;
            s.entries.append(Entry::decode(e.value(4).toInt(), e.value(2).toInt(),
                                           e.value(3).toString(), e.value(5).toInt()));
        }
    }
    w.sessions = sessions.values();

    QSqlQuery n(db());
    n.prepare(QStringLiteral("SELECT %1, injured FROM weeks WHERE owner = ? AND monday = ?")
                  .arg(noteColumn(variant)));
    n.addBindValue(athleteId);
    n.addBindValue(dateString(monday));
    if (exec(n) && n.next()) {
        w.note = n.value(0).toString();
        w.injured = n.value(1).toInt() != 0;
    }
    return w;
}

bool saveSession(const QString &athleteId, const QDate &monday, Variant variant,
                 const Session &session)
{
    QSqlDatabase d = db();
    d.transaction();
    if (!insertSession(athleteId, monday, variant, session, now())) {
        d.rollback();
        return false;
    }
    return d.commit();
}

bool removeSession(const QString &athleteId, const QDate &monday, Variant variant, int day,
                   int number)
{
    QSqlDatabase d = db();
    d.transaction();
    const QDateTime stamp = now();
    for (const char *table : {"session_entries", "sessions"}) {
        if (!deleteRows(QLatin1String(table),
                        QStringLiteral("athlete_id = ? AND monday = ? AND day = ? AND number = ? AND variant = ?"),
                        {athleteId, dateString(monday), day, number, variantString(variant)}, stamp)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

bool saveWeekNote(const QString &athleteId, const QDate &monday, Variant variant,
                  const QString &note, bool injured)
{
    QSqlDatabase d = db();
    d.transaction();
    QSqlQuery ins(d);
    ins.prepare(QStringLiteral("INSERT OR IGNORE INTO weeks (owner, monday) VALUES (?, ?)"));
    ins.addBindValue(athleteId);
    ins.addBindValue(dateString(monday));
    QSqlQuery upd(d);
    upd.prepare(QStringLiteral("UPDATE weeks SET %1 = ?, injured = ?, changed_by = ?, changed_at = ?"
                               " WHERE owner = ? AND monday = ?")
                    .arg(noteColumn(variant)));
    upd.addBindValue(note);
    upd.addBindValue(injured ? 1 : 0);
    upd.addBindValue(kUser);
    upd.addBindValue(stampText(now()));
    upd.addBindValue(athleteId);
    upd.addBindValue(dateString(monday));
    if (!exec(ins) || !exec(upd)) {
        d.rollback();
        return false;
    }
    return d.commit();
}

int copyWeek(const QString &fromAthlete, const QDate &fromMonday, Variant fromVariant,
             const QString &toAthlete, const QDate &toMonday, Variant toVariant)
{
    const Week source = loadWeek(fromAthlete, fromMonday, fromVariant);
    return replaceSessions(toAthlete, toMonday, toVariant, source.sessions)
               ? int(source.sessions.size()) : -1;
}

bool replaceSessions(const QString &toAthlete, const QDate &toMonday, Variant toVariant,
                     const QList<Session> &sessions)
{
    const Week target = loadWeek(toAthlete, toMonday, toVariant);

    QSqlDatabase d = db();
    d.transaction();
    const QDateTime stamp = now();
    for (const Session &s : target.sessions) {
        for (const char *table : {"session_entries", "sessions"}) {
            if (!deleteRows(QLatin1String(table),
                            QStringLiteral("athlete_id = ? AND monday = ? AND day = ? AND number = ? AND variant = ?"),
                            {toAthlete, dateString(toMonday), s.day, s.number, variantString(toVariant)},
                            stamp)) {
                d.rollback();
                return false;
            }
        }
    }
    for (const Session &s : sessions) {
        if (!insertSession(toAthlete, toMonday, toVariant, s, stamp)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

} // namespace Database
