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
