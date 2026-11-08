#pragma once

#include <QList>
#include <QString>
#include <QStringList>

// The tables as they appear in data exports: column order of the old
// program's statements, the primary key, and the columns the new database
// keeps. Shared by the importer, the exporter and the deletion log.
struct TableSpec
{
    QString name;
    QStringList columns; // order in exported statements
    QStringList keys;
    QStringList stored;  // columns of the SQLite table
};

namespace Tables {

const QList<TableSpec> &all();
const TableSpec *find(const QString &name);

} // namespace Tables
