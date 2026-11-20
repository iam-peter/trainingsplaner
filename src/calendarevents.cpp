#include "calendarevents.h"

#include "database.h"

#include <QDateTime>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

namespace CalendarEvents {

namespace {

const QString kUser = QStringLiteral("local");

bool exec(QSqlQuery &q)
{
    if (q.exec())
        return true;
    qWarning("SQL error: %s", qPrintable(q.lastError().text()));
    return false;
}

QList<Event> read(QSqlQuery &q)
{
    QList<Event> list;
    if (!exec(q))
        return list;
    while (q.next()) {
        Event e;
        e.id = q.value(0).toString();
        e.athleteId = q.value(1).toString();
        e.kind = q.value(2).toInt();
        e.first = QDate::fromString(q.value(3).toString(), Qt::ISODate);
        e.last = QDate::fromString(q.value(4).toString(), Qt::ISODate);
        if (!e.last.isValid())
            e.last = e.first;
        e.title = q.value(5).toString();
        e.place = q.value(6).toString();
        e.note = q.value(7).toString();
        list.append(e);
    }
    return list;
}

const QString kColumns = QStringLiteral("id, athlete_id, kind, first_date, last_date, title, place, note");

} // namespace

QStringList kindNames()
{
    return {QStringLiteral("Lehrgang"), QStringLiteral("Diagnostik/Test")};
}

QList<Event> between(const QString &athleteId, const QDate &from, const QDate &to)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT %1 FROM calendar_events WHERE athlete_id = ? AND first_date <= ?"
                             " AND COALESCE(last_date, first_date) >= ? ORDER BY first_date, title")
                  .arg(kColumns));
    q.addBindValue(athleteId);
    q.addBindValue(to.toString(Qt::ISODate));
    q.addBindValue(from.toString(Qt::ISODate));
    return read(q);
}

Event find(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT %1 FROM calendar_events WHERE id = ?").arg(kColumns));
    q.addBindValue(id);
    const QList<Event> list = read(q);
    return list.isEmpty() ? Event() : list.first();
}

QString save(const Event &e)
{
    if (e.athleteId.isEmpty() || !e.first.isValid())
        return {};
    const QString id = e.id.isEmpty() ? QStringLiteral("termin_") + QString::number(QDateTime::currentMSecsSinceEpoch())
                                      : e.id;
    const QDate last = e.last.isValid() && e.last >= e.first ? e.last : e.first;
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO calendar_events (id, athlete_id, kind, first_date, last_date,"
                             " title, place, note, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(e.athleteId);
    q.addBindValue(e.kind == Diagnostik ? int(Diagnostik) : int(Lehrgang));
    q.addBindValue(e.first.toString(Qt::ISODate));
    q.addBindValue(last.toString(Qt::ISODate));
    q.addBindValue(e.title.simplified());
    q.addBindValue(e.place.simplified());
    q.addBindValue(e.note);
    q.addBindValue(kUser);
    q.addBindValue(Database::stampText(Database::now()));
    return exec(q) ? id : QString();
}

bool remove(const QString &id)
{
    return Database::deleteRows(QStringLiteral("calendar_events"), QStringLiteral("id = ?"), {id}, Database::now());
}

QString daysText(const Event &e)
{
    if (!e.last.isValid() || e.last == e.first)
        return e.first.toString(QStringLiteral("dd.MM.yyyy"));
    const QString from = e.first.year() == e.last.year() ? e.first.toString(QStringLiteral("dd.MM."))
                                                         : e.first.toString(QStringLiteral("dd.MM.yyyy"));
    return from + QStringLiteral("–") + e.last.toString(QStringLiteral("dd.MM.yyyy"));
}

} // namespace CalendarEvents
