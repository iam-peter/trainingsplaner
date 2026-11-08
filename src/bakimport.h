#pragma once

#include <QByteArray>
#include <QMap>
#include <QString>
#include <QStringList>
#include <QVariant>

// Imports the data export of the old program (winwotaxp.bak).
//
// The file is a list of MySQL statements: for every row a conditional
// DELETE followed by an "INSERT IGNORE INTO <table> VALUES (...)". Rows are
// merged by primary key; an incoming row only replaces a local row when it
// is at least as new (column `korrektur`). Rows marked deleted (del = "Y")
// remove the local row.
namespace BakImport {

struct TableCount
{
    int added = 0;
    int updated = 0;
    int removed = 0;
    int skipped = 0; // local row is the same or newer
};

struct Result
{
    bool ok = false;
    QMap<QString, TableCount> tables;
    int ignoredStatements = 0;
    QStringList errors;

    QString summary() const;
};

// A parsed INSERT statement; exposed for tests.
struct Row
{
    QString table;
    QList<QVariant> values; // NULL -> invalid QVariant, NOW() -> current time
};

QList<Row> parse(const QString &text, int *ignoredStatements = nullptr,
                 QStringList *errors = nullptr);

// The old program wrote Windows-1252 text.
QString decode(const QByteArray &bytes);

// With ignoreTimestamps every incoming row replaces the local one.
Result importText(const QString &text, bool ignoreTimestamps = false);
Result importFile(const QString &path, bool ignoreTimestamps = false);

} // namespace BakImport
