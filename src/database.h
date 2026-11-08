#pragma once

#include "model.h"

#include <QList>
#include <QString>
#include <QVariantList>

// Storage in a single SQLite file.
//
// The tables and columns follow the old program's database (sp, te, te_ueb,
// wo, normen) so imported data maps one to one. Every row carries a
// `korrektur` timestamp (last change); the importer uses it to decide
// whether an incoming row is newer than the local one.
namespace Database {

bool open(const QString &path, QString *error = nullptr);
void close();
QString path();

QString now();

// Athletes
QList<Athlete> athletes();
Athlete athlete(const QString &id);
// Inserts when `a.id` is empty (a new id is generated) and returns the id.
QString saveAthlete(const Athlete &a);
// Removes the athlete together with all training data.
bool removeAthlete(const QString &id);
int sessionCount(const QString &athleteId);

// Weeks and sessions
Week loadWeek(const QString &athleteId, const QDate &monday, Variant variant);
bool saveSession(const QString &athleteId, const QDate &monday, Variant variant,
                 const Session &session);
bool removeSession(const QString &athleteId, const QDate &monday, Variant variant, int day,
                   int number);
bool saveWeekNote(const QString &athleteId, const QDate &monday, Variant variant,
                  const QString &note, bool injured);
// Replaces the sessions of the target week with copies of the source week.
// Returns the number of sessions copied, or -1 on error.
int copyWeek(const QString &fromAthlete, const QDate &fromMonday, Variant fromVariant,
             const QString &toAthlete, const QDate &toMonday, Variant toVariant);

// Records of an athlete with a time range or a date (table spinfo):
// attributes such as Kader or Verein (art = attribute name, info_text =
// value), and extra info per day (art = category code, info_zahl = value).
struct InfoRecord
{
    QString athleteId;
    QString art;
    QDate from;
    QString time = QStringLiteral("00:00:00");
    QDate to;          // invalid: open end
    QString text;
    double number = 0;
    bool hasNumber = false;
};
QList<InfoRecord> infoRecords(const QString &athleteId, const QString &art);
// All records of these kinds for all athletes (to show current values)
QList<InfoRecord> infoRecords(const QStringList &arts);
bool saveInfoRecord(const InfoRecord &r);
bool removeInfoRecord(const QString &athleteId, const QString &art, const QDate &from,
                      const QString &time = QStringLiteral("00:00:00"));
QStringList infoValues(const QString &art); // distinct texts, sorted
// The record valid on `date` (from <= date <= to), or nullptr
const InfoRecord *infoAt(const QList<InfoRecord> &records, const QDate &date);
// Sets an attribute from `date` on: the record valid until then ends the day
// before, a new record starts (or the one starting on `date` changes). An
// empty value only ends the current record.
bool setAttribute(const QString &athleteId, const QString &art, const QString &value,
                  const QDate &date);

// Generic access for the other modules
bool deleteRows(const QString &table, const QString &where, const QVariantList &binds,
                const QString &stamp);
bool recordDeletion(const QString &table, const QVariantList &key, const QString &stamp);
struct Deletion
{
    QStringList key;
    QString stamp;
};
QList<Deletion> deletions(const QString &table, const QString &since);

QString lastError();

} // namespace Database
