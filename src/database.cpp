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
    // Athlete attributes with a time range (art = Kader, Verein, ...) and
    // extra info per day (art = KG, KF, ...: info_zahl at von/zeit)
    "CREATE TABLE IF NOT EXISTS spinfo ("
    " spid TEXT NOT NULL, art TEXT NOT NULL, von TEXT NOT NULL, zeit TEXT NOT NULL DEFAULT '00:00:00',"
    " bis TEXT, info_text TEXT, info_zahl REAL, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (spid, art, von, zeit))",
    // Competitions; a negative attempt was invalid
    "CREATE TABLE IF NOT EXISTS wk ("
    " spid TEXT NOT NULL, datum TEXT NOT NULL, zeit TEXT NOT NULL DEFAULT '00:00:00',"
    " wkart INTEGER, wk TEXT, ort TEXT, gew REAL, rei1 INTEGER, rei2 INTEGER, rei3 INTEGER,"
    " sto1 INTEGER, sto2 INTEGER, sto3 INTEGER, zk INTEGER, bem TEXT, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (spid, datum, zeit))",
    // Macrocycles (MAZ); von/bis/abp_von/lap_von are Mondays
    "CREATE TABLE IF NOT EXISTS maz ("
    " id TEXT PRIMARY KEY, sex INTEGER DEFAULT 0, bez TEXT, kbez TEXT, von TEXT, bis TEXT,"
    " abp_von TEXT, lap_von TEXT, bem TEXT, user TEXT, korrektur TEXT)",
    "CREATE TABLE IF NOT EXISTS maz_sp ("
    " mazid TEXT NOT NULL, spid TEXT NOT NULL, gew INTEGER, ziel_rei INTEGER, ziel_sto INTEGER,"
    " wk_rei INTEGER, wk_sto INTEGER, auswahl INTEGER NOT NULL DEFAULT 1, bem TEXT, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (mazid, spid))",
    // Week targets per exercise: ITP (spid = athlete) or framework plan (spid = '#' + MAZ id);
    // ueb -1..-7 stand for the groups K1..K7
    "CREATE TABLE IF NOT EXISTS ueb ("
    " spid TEXT NOT NULL, wodate TEXT NOT NULL, ueb INTEGER NOT NULL, spi TEXT NOT NULL DEFAULT 'S',"
    " wh INTEGER, mhg INTEGER, bw INTEGER, bwsg INTEGER, bwsganz INTEGER, user TEXT, korrektur TEXT,"
    " PRIMARY KEY (spid, wodate, ueb, spi))",
    "CREATE TABLE IF NOT EXISTS itp_ls ("
    " spid TEXT NOT NULL, wodate TEXT NOT NULL, ueb INTEGER NOT NULL, lststbem TEXT, user TEXT,"
    " korrektur TEXT, PRIMARY KEY (spid, wodate, ueb))",
    // Deleted rows, so an export of changes can pass deletions on
    "CREATE TABLE IF NOT EXISTS geloescht ("
    " tabelle TEXT NOT NULL, schluessel TEXT NOT NULL, korrektur TEXT,"
    " PRIMARY KEY (tabelle, schluessel))",
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

// The tables' layout; meta.schema says which one a database file has.
// 1: up to version 0.3.0. 2: maz_sp.auswahl is 0/1 instead of 'Y'/'N',
// sessions without a time have NULL, change stamps one form.
constexpr int kSchemaVersion = 2;

const char *const kStampedTables[] = {"sp", "te", "te_ueb", "wo", "normen", "spinfo", "wk",
                                      "maz", "maz_sp", "ueb", "itp_ls", "geloescht"};

QString createStatement(const char *table)
{
    const QString head = QStringLiteral("CREATE TABLE IF NOT EXISTS %1 (").arg(QLatin1String(table));
    for (const char *sql : kSchema) {
        if (QString::fromLatin1(sql).startsWith(head))
            return QString::fromLatin1(sql);
    }
    return QString();
}

int schemaVersion()
{
    QSqlQuery q(db());
    if (!q.exec(QStringLiteral("SELECT value FROM meta WHERE key = 'schema'")) || !q.next())
        return 0;
    return q.value(0).toInt();
}

bool migrateTo2()
{
    QStringList steps = {
        // SQLite cannot change a column's type: the table is built anew
        QStringLiteral("ALTER TABLE maz_sp RENAME TO maz_sp_v1"),
        createStatement("maz_sp"),
        QStringLiteral("INSERT INTO maz_sp (mazid, spid, gew, ziel_rei, ziel_sto, wk_rei, wk_sto, auswahl,"
                       " bem, user, korrektur)"
                       " SELECT mazid, spid, gew, ziel_rei, ziel_sto, wk_rei, wk_sto,"
                       " CASE WHEN upper(trim(coalesce(auswahl, ''))) IN ('N', '0') THEN 0 ELSE 1 END,"
                       " bem, user, korrektur FROM maz_sp_v1"),
        QStringLiteral("DROP TABLE maz_sp_v1"),
    };
    // One form of "no time" (NULL) and of a time (15:30:00)
    for (const char *column : {"von", "bis"}) {
        steps.append(QStringLiteral("UPDATE te SET %1 = NULL WHERE trim(%1) IN ('', '00:00:00')")
                         .arg(QLatin1String(column)));
        steps.append(QStringLiteral("UPDATE te SET %1 = strftime('%H:%M:%S', %1)"
                                    " WHERE strftime('%H:%M:%S', %1) IS NOT NULL")
                         .arg(QLatin1String(column)));
    }
    // Imported stamps came as the file had them, e.g. with a T
    for (const char *table : kStampedTables) {
        steps.append(QStringLiteral("UPDATE %1 SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur)"
                                    " WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL")
                         .arg(QLatin1String(table)));
    }
    for (const QString &sql : std::as_const(steps)) {
        if (!execSql(sql))
            return false;
    }
    return true;
}

// A copy of the file as the older program left it, before changing it:
// "trainingsplaner.sqlite" -> "trainingsplaner.schema1.sqlite"
bool keepCopy(const QString &path, int version)
{
    const QFileInfo info(path);
    const QString copy = info.dir().filePath(QStringLiteral("%1.schema%2.%3")
                                                 .arg(info.completeBaseName())
                                                 .arg(version)
                                                 .arg(info.suffix()));
    if (QFileInfo::exists(copy) || QFile::copy(path, copy))
        return true;
    g_lastError = QStringLiteral("Sicherungskopie %1 nicht angelegt").arg(copy);
    return false;
}

// Brings a database file from an older program up to date, all or nothing
bool migrate(int from)
{
    QSqlDatabase d = db();
    d.transaction();
    bool ok = true;
    if (from < 2)
        ok = migrateTo2();
    ok = ok && execSql(QStringLiteral("UPDATE meta SET value = '%1' WHERE key = 'schema'").arg(kSchemaVersion));
    if (!ok) {
        d.rollback();
        return false;
    }
    return d.commit();
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
        q.prepare(QStringLiteral("SELECT 1 FROM sp WHERE spid = ?"));
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
        QSqlQuery sel(db());
        sel.prepare(QStringLiteral("SELECT %1 FROM %2 WHERE %3")
                        .arg(spec->keys.join(QStringLiteral(", ")), table, where));
        for (const QVariant &b : binds)
            sel.addBindValue(b);
        if (!exec(sel))
            return false;
        while (sel.next()) {
            QVariantList key;
            for (int i = 0; i < spec->keys.size(); ++i)
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
    q.addBindValue(Database::stampText(stamp));
    if (!exec(q))
        return false;

    // Lines beyond the new count are gone; the others are written again.
    if (!deleteLogged(QStringLiteral("te_ueb"),
                    QStringLiteral("spid = ? AND wodate = ? AND tag = ? AND te = ? AND spi = ? AND pos > ?"),
                    {athleteId, dateString(monday), s.day, s.number, variantString(variant),
                     int(s.entries.size())},
                    stamp))
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
    return time;
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
    // A new file has the current tables; an older one is brought up to date
    // once, one from a newer program is left alone
    const int version = schemaVersion();
    if (version == 0) {
        execSql(QStringLiteral("INSERT INTO meta (key, value) VALUES ('schema', '%1')").arg(kSchemaVersion));
    } else if (version > kSchemaVersion) {
        g_lastError = QStringLiteral("Die Datenbank stammt von einer neueren Version des Trainingsplaners.");
        if (error)
            *error = g_lastError;
        d = QSqlDatabase();
        close();
        return false;
    } else if (version < kSchemaVersion && !(keepCopy(path, version) && migrate(version))) {
        if (error)
            *error = QStringLiteral("Die Datenbank ließ sich nicht aktualisieren: ") + g_lastError;
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
        "INSERT OR REPLACE INTO sp (spid, name, vorname, sex, geb, adresse, telefon, user,"
        " korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
    for (const char *table : {"te_ueb", "te", "wo", "spinfo", "wk", "maz_sp", "ueb", "itp_ls", "sp"}) {
        if (!deleteRows(QLatin1String(table), QStringLiteral("spid = ?"), {id}, stamp)) {
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

const QString kInfoColumns = QStringLiteral("spid, art, von, zeit, bis, info_text, info_zahl");

} // namespace

QList<InfoRecord> infoRecords(const QString &athleteId, const QString &art)
{
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT %1 FROM spinfo WHERE spid = ? AND art = ? ORDER BY von, zeit")
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
    q.prepare(QStringLiteral("SELECT %1 FROM spinfo WHERE art IN (%2) ORDER BY spid, art, von, zeit")
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
    q.prepare(QStringLiteral("SELECT %1 FROM spinfo WHERE spid = ? AND art IN (%2) AND von BETWEEN ? AND ?"
                             " ORDER BY von, zeit, art")
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

bool saveInfoRecord(const InfoRecord &r)
{
    if (r.athleteId.isEmpty() || r.art.isEmpty() || !r.from.isValid())
        return false;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO spinfo (spid, art, von, zeit, bis, info_text,"
                             " info_zahl, user, korrektur) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
    return deleteRows(QStringLiteral("spinfo"), QStringLiteral("spid = ? AND art = ? AND von = ? AND zeit = ?"),
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
            && !deleteRows(QStringLiteral("spinfo"),
                           QStringLiteral("spid = ? AND art = ? AND von = ? AND zeit = ?"),
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
    q.prepare(QStringLiteral("SELECT DISTINCT info_text FROM spinfo WHERE art = ? AND info_text <> ''"
                             " ORDER BY info_text COLLATE NOCASE"));
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
    q.prepare(QStringLiteral("SELECT wodate, tag, te, lststbem FROM te_ueb WHERE spid = ? AND spi = ?"
                             " AND ueb = ? AND art = 0 AND wodate BETWEEN ? AND ? ORDER BY wodate, tag, te, pos"));
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

QList<WeightLine> weightLines(const QString &athleteId, Variant variant, const QDate &fromMonday,
                              const QDate &toMonday)
{
    QList<WeightLine> list;
    QSqlQuery q(db());
    q.prepare(QStringLiteral("SELECT wodate, tag, ueb, lststbem FROM te_ueb WHERE spid = ? AND spi = ?"
                             " AND art = 0 AND ueb > 0 AND wodate BETWEEN ? AND ? ORDER BY wodate, tag, te, pos"));
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
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO geloescht (tabelle, schluessel, korrektur)"
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
    q.prepare(QStringLiteral("SELECT schluessel, korrektur FROM geloescht WHERE tabelle = ?%1"
                             " ORDER BY korrektur")
                  .arg(since.isValid() ? QStringLiteral(" AND korrektur >= ?") : QString()));
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
    const QDateTime stamp = now();
    for (const char *table : {"te_ueb", "te"}) {
        if (!deleteRows(QLatin1String(table),
                        QStringLiteral("spid = ? AND wodate = ? AND tag = ? AND te = ? AND spi = ?"),
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
        for (const char *table : {"te_ueb", "te"}) {
            if (!deleteRows(QLatin1String(table),
                            QStringLiteral("spid = ? AND wodate = ? AND tag = ? AND te = ? AND spi = ?"),
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
