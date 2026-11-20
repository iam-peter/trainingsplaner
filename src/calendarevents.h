#pragma once

#include <QDate>
#include <QList>
#include <QString>
#include <QStringList>

// Calendar entries beside the competitions, as IDA has them: a Lehrgang
// (training camp) over several days and a Diagnostik/Test on one day,
// each for one athlete (table calendar_events, new in this program).
namespace CalendarEvents {

enum Kind { Lehrgang = 1, Diagnostik = 2 };

struct Event
{
    QString id;
    QString athleteId;
    int kind = Lehrgang;
    QDate first;
    QDate last; // the same as first for a single day
    QString title;
    QString place;
    QString note;
};

// "Lehrgang", "Diagnostik/Test", in kind order from 1
QStringList kindNames();

// The athlete's entries that touch the days from..to, by first day
QList<Event> between(const QString &athleteId, const QDate &from, const QDate &to);
Event find(const QString &id);
// Returns the id (a new one for an event without), "" on error
QString save(const Event &e);
bool remove(const QString &id);

// "16.11.–20.11.2026", or one day "16.11.2026"
QString daysText(const Event &e);

} // namespace CalendarEvents
