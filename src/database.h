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
// Replaces all sessions of a week with the given ones.
bool replaceSessions(const QString &athleteId, const QDate &monday, Variant variant,
                     const QList<Session> &sessions);
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
// Makes `records` the whole history of one attribute in one step:
// records starting on a day no longer in it are removed
bool replaceInfoRecords(const QString &athleteId, const QString &art,
                        const QList<InfoRecord> &records);
QStringList infoValues(const QString &art); // distinct texts, sorted
// Records of the given kinds dated from..to (inclusive)
QList<InfoRecord> infoRecordsBetween(const QString &athleteId, const QStringList &arts,
                                     const QDate &from, const QDate &to);
// The record valid on `date` (from <= date <= to), or nullptr
const InfoRecord *infoAt(const QList<InfoRecord> &records, const QDate &date);
// Sets an attribute from `date` on: the record valid until then ends the day
// before, a new record starts (or the one starting on `date` changes). An
// empty value only ends the current record.
bool setAttribute(const QString &athleteId, const QString &art, const QString &value,
                  const QDate &date);

// Every use of a weight exercise by an athlete between two Mondays
struct ExerciseUse
{
    QDate monday;
    int day = 1;
    int number = 1;
    QList<Step> steps;
};
QList<ExerciseUse> exerciseUses(const QString &athleteId, Variant variant, int exercise,
                                const QDate &fromMonday, const QDate &toMonday);
// All weight lines of an athlete between two Mondays: (monday, exercise, steps)
struct WeightLine
{
    QDate monday;
    int day = 1;
    int exercise = 0;
    QList<Step> steps;
};
QList<WeightLine> weightLines(const QString &athleteId, Variant variant, const QDate &fromMonday,
                              const QDate &toMonday);

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
