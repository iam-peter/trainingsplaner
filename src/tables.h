#pragma once

#include <QList>
#include <QMap>
#include <QString>
#include <QStringList>
#include <QVariant>

// Where a column's values in the old program's files differ from the
// stored ones
enum class ColumnFormat {
    Plain,
    YesNo,        // file "Y" or "N", stored 1 or 0
    OptionalTime, // file 00:00:00 for none, stored NULL
};

// A table of the database and how it appears in the old program's data
// files, which name tables and columns in German (sp, te, wodate, ...).
// Shared by the importer, the exporter and the deletion log.
struct TableSpec
{
    QString name;            // in the database, e.g. "sessions"
    QString fileName;        // in the files, e.g. "te"
    QStringList fileColumns; // in the order of the files' statements
    QStringList fileKeys;    // the files' key columns
    QMap<QString, QString> columnOf;     // file column -> database column
    QMap<QString, ColumnFormat> formats; // database columns that are not Plain

    // The database column of a file column; empty for the files' own
    // columns del and korrektur2, which are not stored
    QString column(const QString &fileColumn) const { return columnOf.value(fileColumn); }
    QStringList keys() const;   // database key columns, in the files' order
    QStringList stored() const; // database columns, in the files' order

    QVariant toStored(const QString &column, const QVariant &fileValue) const;
    QVariant toFile(const QString &column, const QVariant &storedValue) const;
};

namespace Tables {

const QList<TableSpec> &all();
const TableSpec *find(const QString &name);         // by database name
const TableSpec *findFile(const QString &fileName); // by the files' name
QString label(const QString &name); // for people: "Trainingseinheiten"

} // namespace Tables
