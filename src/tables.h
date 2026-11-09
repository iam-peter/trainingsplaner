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

// The tables as they appear in data exports: column order of the old
// program's statements, the primary key, and the columns the new database
// keeps. Shared by the importer, the exporter and the deletion log.
struct TableSpec
{
    QString name;
    QStringList columns; // order in exported statements
    QStringList keys;
    QStringList stored;  // columns of the SQLite table
    QMap<QString, ColumnFormat> formats; // columns that are not Plain

    QVariant toStored(const QString &column, const QVariant &fileValue) const;
    QVariant toFile(const QString &column, const QVariant &storedValue) const;
};

namespace Tables {

const QList<TableSpec> &all();
const TableSpec *find(const QString &name);

} // namespace Tables
