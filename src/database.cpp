#include "database.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

namespace {

QString g_lastError;

const char *kSchema[] = {
    "CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT)",
    // Athletes ("Sportler")
    "CREATE TABLE IF NOT EXISTS sp ("
    " spid TEXT PRIMARY KEY, name TEXT NOT NULL DEFAULT '', vorname TEXT NOT NULL DEFAULT '',"
    " sex INTEGER NOT NULL DEFAULT 0, geb TEXT, adresse TEXT, telefon TEXT,"
    " user TEXT, korrektur TEXT)",
    // Training sessions ("Trainingseinheiten"); wodate is the Monday of the week,
    // tag 1-7 the weekday, te the session number, spi P (plan) or I (actual).
    "CREATE TABLE IF NOT EXISTS te ("
    " spid TEXT NOT NULL, wodate TEXT NOT NULL, tag INTEGER NOT NULL, te INTEGER NOT NULL,"
    " spi TEXT NOT NULL, art INTEGER DEFAULT 0, von TEXT, bis TEXT, bem TEXT,"
    " user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate, tag, te, spi))",
    // Lines of a session; lststbem holds the encoded content (see Entry::encode).
    "CREATE TABLE IF NOT EXISTS te_ueb ("
    " spid TEXT NOT NULL, wodate TEXT NOT NULL, tag INTEGER NOT NULL, te INTEGER NOT NULL,"
    " pos INTEGER NOT NULL, spi TEXT NOT NULL, ueb INTEGER DEFAULT 0, lststbem TEXT,"
    " art INTEGER DEFAULT 0, kombi INTEGER DEFAULT 0, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (spid, wodate, tag, te, pos, spi))",
    // Week notes
    "CREATE TABLE IF NOT EXISTS wo ("
    " spid TEXT NOT NULL, wodate TEXT NOT NULL, bel INTEGER, wklg TEXT, verletzt INTEGER,"
    " bem_soll TEXT, bem_plan TEXT, bem_ist TEXT, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (spid, wodate))",
    // Reference totals by sex, age class and weight class (from the old program)
    "CREATE TABLE IF NOT EXISTS normen ("
    " sex INTEGER NOT NULL, akl INTEGER NOT NULL, gkl INTEGER NOT NULL, gklbez TEXT,"
    " zk INTEGER, user TEXT, korrektur TEXT, PRIMARY KEY (sex, akl, gkl))",
};

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
    return v == Variant::Plan ? QStringLiteral("bem_plan") : QStringLiteral("bem_ist");
}

QString timeToStorage(const QString &t)
{
    const QString s = t.trimmed();
    if (s.isEmpty())
        return QString();
    return s.size() == 5 ? s + QStringLiteral(":00") : s;
}

QString timeFromStorage(const QString &t)
{
    if (t.isEmpty() || t == QLatin1String("00:00:00"))
        return QString();
    return t.left(5);
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
        q.prepare(QStringLiteral("SELECT 1 FROM sp WHERE spid = ?"));
        q.addBindValue(id);
        if (!exec(q) || !q.next())
            return id;
        id = base + QLatin1Char('_') + QString::number(n);
    }
}

bool insertSession(const QString &athleteId, const QDate &monday, Variant variant,
                   const Session &s, const QString &stamp)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO te (spid, wodate, tag, te, spi, art, von, bis, bem, user, korrektur)"
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
    q.addBindValue(stamp);
    if (!exec(q))
        return false;

    QSqlQuery del(db());
    del.prepare(QStringLiteral(
        "DELETE FROM te_ueb WHERE spid = ? AND wodate = ? AND tag = ? AND te = ? AND spi = ?"));
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
            "INSERT INTO te_ueb (spid, wodate, tag, te, pos, spi, ueb, lststbem, art, kombi,"
            " user, korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
        ins.addBindValue(stamp);
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

QString now()
{
    return QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

bool open(const QString &path, QString *error)
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    d.setDatabaseName(path);
    if (!d.open()) {
        if (error)
            *error = d.lastError().text();
        return false;
    }
    execSql(QStringLiteral("PRAGMA foreign_keys = ON"));
    for (const char *sql : kSchema) {
        if (!execSql(QString::fromLatin1(sql))) {
            if (error)
                *error = g_lastError;
            return false;
        }
    }
    execSql(QStringLiteral("INSERT OR IGNORE INTO meta (key, value) VALUES ('schema', '1')"));
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

QList<Athlete> athletes()
{
    QList<Athlete> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral(
        "SELECT spid, name, vorname, sex, geb, adresse, telefon FROM sp"
        " ORDER BY name COLLATE NOCASE, vorname COLLATE NOCASE"));
    if (!exec(q))
        return list;
    while (q.next()) {
        Athlete a;
        a.id = q.value(0).toString();
        a.lastName = q.value(1).toString();
        a.firstName = q.value(2).toString();
        a.sex = q.value(3).toInt();
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
        "INSERT OR REPLACE INTO sp (spid, name, vorname, sex, geb, adresse, telefon, user,"
        " korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(a.lastName.trimmed());
    q.addBindValue(a.firstName.trimmed());
    q.addBindValue(a.sex);
    q.addBindValue(a.born.isValid() ? dateString(a.born) : QVariant());
    q.addBindValue(a.address);
    q.addBindValue(a.phone);
    q.addBindValue(kUser);
    q.addBindValue(now());
    return exec(q) ? id : QString();
}

bool removeAthlete(const QString &id)
{
    QSqlDatabase d = db();
    d.transaction();
    for (const char *table : {"te_ueb", "te", "wo", "sp"}) {
        QSqlQuery q(d);
        q.prepare(QStringLiteral("DELETE FROM %1 WHERE spid = ?").arg(QLatin1String(table)));
        q.addBindValue(id);
        if (!exec(q)) {
            d.rollback();
            return false;
        }
    }
    return d.commit();
}

int sessionCount(const QString &athleteId)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT COUNT(*) FROM te WHERE spid = ?"));
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
    q.prepare(QStringLiteral("SELECT tag, te, von, bis, bem FROM te"
                             " WHERE spid = ? AND wodate = ? AND spi = ?"));
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
    e.prepare(QStringLiteral("SELECT tag, te, ueb, lststbem, art, kombi FROM te_ueb"
                             " WHERE spid = ? AND wodate = ? AND spi = ? ORDER BY tag, te, pos"));
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
    n.prepare(QStringLiteral("SELECT %1, verletzt FROM wo WHERE spid = ? AND wodate = ?")
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
    for (const char *table : {"te_ueb", "te"}) {
        QSqlQuery q(d);
        q.prepare(QStringLiteral("DELETE FROM %1 WHERE spid = ? AND wodate = ? AND tag = ?"
                                 " AND te = ? AND spi = ?")
                      .arg(QLatin1String(table)));
        q.addBindValue(athleteId);
        q.addBindValue(dateString(monday));
        q.addBindValue(day);
        q.addBindValue(number);
        q.addBindValue(variantString(variant));
        if (!exec(q)) {
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
    ins.prepare(QStringLiteral("INSERT OR IGNORE INTO wo (spid, wodate) VALUES (?, ?)"));
    ins.addBindValue(athleteId);
    ins.addBindValue(dateString(monday));
    QSqlQuery upd(d);
    upd.prepare(QStringLiteral("UPDATE wo SET %1 = ?, verletzt = ?, user = ?, korrektur = ?"
                               " WHERE spid = ? AND wodate = ?")
                    .arg(noteColumn(variant)));
    upd.addBindValue(note);
    upd.addBindValue(injured ? 1 : 0);
    upd.addBindValue(kUser);
    upd.addBindValue(now());
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
    const Week target = loadWeek(toAthlete, toMonday, toVariant);

    QSqlDatabase d = db();
    d.transaction();
    for (const Session &s : target.sessions) {
        for (const char *table : {"te_ueb", "te"}) {
            QSqlQuery q(d);
            q.prepare(QStringLiteral("DELETE FROM %1 WHERE spid = ? AND wodate = ? AND tag = ?"
                                     " AND te = ? AND spi = ?")
                          .arg(QLatin1String(table)));
            q.addBindValue(toAthlete);
            q.addBindValue(dateString(toMonday));
            q.addBindValue(s.day);
            q.addBindValue(s.number);
            q.addBindValue(variantString(toVariant));
            if (!exec(q)) {
                d.rollback();
                return -1;
            }
        }
    }
    const QString stamp = now();
    for (const Session &s : source.sessions) {
        if (!insertSession(toAthlete, toMonday, toVariant, s, stamp)) {
            d.rollback();
            return -1;
        }
    }
    if (!d.commit())
        return -1;
    return int(source.sessions.size());
}

} // namespace Database
