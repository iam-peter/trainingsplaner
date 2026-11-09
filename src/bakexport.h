#pragma once

#include <QDate>
#include <QDateTime>
#include <QMap>
#include <QString>

// Writes data exports in the old program's format (see BakImport): for every
// row a conditional DELETE and an "INSERT IGNORE INTO ... VALUES (...)", in
// Windows-1252. Deleted rows go out with del = "Y", so the receiving side
// removes them too.
namespace BakExport {

struct Filter
{
    enum Mode {
        All,          // everything
        ChangedSince, // rows changed (or deleted) since `since`
        AthleteWeeks, // one athlete's data from `fromMonday` to `toMonday`
        Maz           // a macrocycle with its athletes and framework plan
    };
    Mode mode = All;
    QDateTime since;
    QString athleteId;
    QString mazId;
    QDate fromMonday;
    QDate toMonday;
};

struct Result
{
    bool ok = false;
    QMap<QString, int> rows;    // per table
    QMap<QString, int> deleted; // deletions per table
    QString error;

    QString summary() const;
};

QString exportText(const Filter &filter, Result *result = nullptr);
Result exportFile(const QString &path, const Filter &filter);

QByteArray encode(const QString &text); // Windows-1252, '?' where impossible

} // namespace BakExport
