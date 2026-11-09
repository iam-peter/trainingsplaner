#include "bakexport.h"

#include "database.h"
#include "tables.h"

#include <QFile>
#include <QSaveFile>
#include <QSet>
#include <QSqlQuery>
#include <QStringList>
#include <QVariant>

namespace {

QString quote(const QVariant &v)
{
    if (!v.isValid() || v.isNull())
        return QStringLiteral("NULL");
    QString s = v.toString();
    QString out;
    out.reserve(s.size() + 2);
    out += QLatin1Char('"');
    for (const QChar c : std::as_const(s)) {
        switch (c.unicode()) {
        case '\\': out += QStringLiteral("\\\\"); break;
        case '"': out += QStringLiteral("\\\""); break;
        case '\n': out += QStringLiteral("\\n"); break;
        case '\r': out += QStringLiteral("\\r"); break;
        case '\t': out += QStringLiteral("\\t"); break;
        case 0: out += QStringLiteral("\\0"); break;
        default: out += c;
        }
    }
    out += QLatin1Char('"');
    return out;
}

// Which rows of a table the filter selects
bool whereFor(const TableSpec &t, const BakExport::Filter &f, QString *where, QVariantList *binds)
{
    using F = BakExport::Filter;
    switch (f.mode) {
    case F::All:
        *where = QStringLiteral("1");
        return true;
    case F::ChangedSince:
        *where = QStringLiteral("changed_at >= ?");
        binds->append(Database::stampText(f.since));
        return true;
    case F::AthleteWeeks: {
        const QString from = f.fromMonday.toString(Qt::ISODate);
        const QString to = f.toMonday.addDays(6).toString(Qt::ISODate);
        if (t.name == QLatin1String("athletes")) {
            *where = QStringLiteral("id = ?");
            *binds = {f.athleteId};
        } else if (t.name == QLatin1String("sessions") || t.name == QLatin1String("session_entries")) {
            *where = QStringLiteral("athlete_id = ? AND monday BETWEEN ? AND ?");
            *binds = {f.athleteId, from, to};
        } else if (t.name == QLatin1String("weeks") || t.name == QLatin1String("week_targets")
                   || t.name == QLatin1String("planned_steps")) {
            *where = QStringLiteral("owner = ? AND monday BETWEEN ? AND ?");
            *binds = {f.athleteId, from, to};
        } else if (t.name == QLatin1String("competitions")) {
            *where = QStringLiteral("athlete_id = ? AND date BETWEEN ? AND ?");
            *binds = {f.athleteId, from, to};
        } else if (t.name == QLatin1String("athlete_info")) {
            *where = QStringLiteral("athlete_id = ?"); // attributes span weeks; all of them
            *binds = {f.athleteId};
        } else {
            return false; // reference totals, macrocycles, ... are not one athlete's data
        }
        return true;
    }
    case F::Maz:
        if (t.name == QLatin1String("macrocycles")) {
            *where = QStringLiteral("id = ?");
            *binds = {f.mazId};
        } else if (t.name == QLatin1String("macrocycle_athletes")) {
            *where = QStringLiteral("macrocycle_id = ?");
            *binds = {f.mazId};
        } else if (t.name == QLatin1String("week_targets") || t.name == QLatin1String("planned_steps")
                   || t.name == QLatin1String("weeks")) {
            *where = QStringLiteral("owner = ?");
            *binds = {QLatin1Char('#') + f.mazId};
        } else {
            return false;
        }
        return true;
    }
    return false;
}

const char16_t kCp1252High[32] = {
    0x20AC, 0, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, 0x2039,
    0x0152, 0, 0x017D, 0, 0, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0, 0x017E, 0x0178};

} // namespace

namespace BakExport {

QString Result::summary() const
{
    QStringList lines;
    int total = 0;
    for (auto it = rows.cbegin(); it != rows.cend(); ++it) {
        total += it.value();
        const int del = deleted.value(it.key());
        lines.append(QStringLiteral("%1: %2 Zeilen%3")
                         .arg(Tables::label(it.key()))
                         .arg(it.value())
                         .arg(del > 0 ? QStringLiteral(", davon %1 gelöscht").arg(del) : QString()));
    }
    if (total == 0)
        lines.prepend(QStringLiteral("Keine Daten für diese Auswahl."));
    if (!error.isEmpty())
        lines.append(QStringLiteral("Fehler: ") + error);
    return lines.join(QLatin1Char('\n'));
}

QByteArray encode(const QString &text)
{
    QByteArray out;
    out.reserve(text.size());
    for (const QChar c : text) {
        const char16_t u = c.unicode();
        if (u < 0x80 || (u >= 0xA0 && u <= 0xFF)) {
            out.append(char(u));
            continue;
        }
        char b = '?';
        for (int i = 0; i < 32; ++i) {
            if (kCp1252High[i] == u) {
                b = char(0x80 + i);
                break;
            }
        }
        out.append(b);
    }
    return out;
}

QString exportText(const Filter &filter, Result *result)
{
    Result local;
    Result &r = result ? *result : local;
    QStringList lines;

    for (const TableSpec &t : Tables::all()) {
        QString where;
        QVariantList binds;
        if (!whereFor(t, filter, &where, &binds))
            continue;

        const QStringList stored = t.stored();
        QSqlQuery q;
        q.prepare(QStringLiteral("SELECT %1 FROM %2 WHERE %3")
                      .arg(stored.join(QStringLiteral(", ")), t.name, where));
        for (const QVariant &b : binds)
            q.addBindValue(b);
        if (!q.exec()) {
            r.error = Database::lastError();
            continue;
        }
        // Rows go out with the files' table and column names
        QSet<QString> liveKeys;
        while (q.next()) {
            QVariantMap row; // by database column
            for (int i = 0; i < stored.size(); ++i)
                row.insert(stored[i], q.value(i));
            QStringList keyCond, values, keyParts;
            for (const QString &k : t.fileKeys) {
                keyCond.append(QStringLiteral("%1=%2").arg(k, quote(row.value(t.column(k)))));
                keyParts.append(row.value(t.column(k)).toString());
            }
            liveKeys.insert(keyParts.join(QChar(0x1f)));
            const QString stamp = row.value(QStringLiteral("changed_at")).toString();
            for (const QString &c : t.fileColumns) {
                if (c == QLatin1String("del"))
                    values.append(QStringLiteral("\"N\""));
                else if (c == QLatin1String("korrektur2"))
                    values.append(QStringLiteral("NOW()"));
                else
                    values.append(quote(t.toFile(t.column(c), row.value(t.column(c)))));
            }
            lines.append(QStringLiteral("DELETE FROM %1 WHERE %2 AND korrektur<%3")
                             .arg(t.fileName, keyCond.join(QStringLiteral(" AND ")), quote(stamp)));
            lines.append(QStringLiteral("INSERT IGNORE INTO %1 VALUES (%2)")
                             .arg(t.fileName, values.join(QLatin1Char(','))));
            ++r.rows[t.name];
        }

        // Deletions, unless the row exists again
        if (filter.mode == Filter::AthleteWeeks || filter.mode == Filter::Maz)
            continue;
        const QDateTime since = filter.mode == Filter::ChangedSince ? filter.since : QDateTime();
        for (const Database::Deletion &d : Database::deletions(t.name, since)) {
            if (d.key.size() != t.fileKeys.size() || liveKeys.contains(d.key.join(QChar(0x1f))))
                continue;
            const QString stamp = Database::stampText(d.stamp);
            QStringList keyCond, values;
            for (int i = 0; i < t.fileKeys.size(); ++i)
                keyCond.append(QStringLiteral("%1=%2").arg(t.fileKeys[i], quote(d.key[i])));
            for (const QString &c : t.fileColumns) {
                const int k = t.fileKeys.indexOf(c);
                if (k >= 0)
                    values.append(quote(d.key[k]));
                else if (c == QLatin1String("del"))
                    values.append(QStringLiteral("\"Y\""));
                else if (c == QLatin1String("korrektur"))
                    values.append(quote(stamp));
                else if (c == QLatin1String("korrektur2"))
                    values.append(QStringLiteral("NOW()"));
                else
                    values.append(QStringLiteral("NULL"));
            }
            lines.append(QStringLiteral("DELETE FROM %1 WHERE %2 AND korrektur<%3")
                             .arg(t.fileName, keyCond.join(QStringLiteral(" AND ")), quote(stamp)));
            lines.append(QStringLiteral("INSERT IGNORE INTO %1 VALUES (%2)")
                             .arg(t.fileName, values.join(QLatin1Char(','))));
            ++r.rows[t.name];
            ++r.deleted[t.name];
        }
    }
    r.ok = r.error.isEmpty();
    return lines.isEmpty() ? QString() : lines.join(QStringLiteral("\r\n")) + QStringLiteral("\r\n");
}

Result exportFile(const QString &path, const Filter &filter)
{
    Result r;
    const QString text = exportText(filter, &r);
    QSaveFile f(path);
    if (!f.open(QIODevice::WriteOnly)) {
        r.ok = false;
        r.error = f.errorString();
        return r;
    }
    f.write(encode(text));
    if (!f.commit()) {
        r.ok = false;
        r.error = f.errorString();
    }
    return r;
}

} // namespace BakExport
