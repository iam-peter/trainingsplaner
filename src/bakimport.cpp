#include "bakimport.h"

#include "database.h"
#include "tables.h"

#include <QFile>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

namespace {

// Minimal scanner for the statements the old program wrote.
class Scanner
{
public:
    explicit Scanner(const QString &text) : m_text(text) {}

    bool atEnd() const { return m_pos >= m_text.size(); }

    void skipSpace()
    {
        while (!atEnd() && m_text.at(m_pos).isSpace())
            ++m_pos;
    }

    bool keyword(const QString &word)
    {
        skipSpace();
        if (m_text.mid(m_pos, word.size()).compare(word, Qt::CaseInsensitive) != 0)
            return false;
        const int end = m_pos + word.size();
        if (end < m_text.size() && (m_text.at(end).isLetterOrNumber() || m_text.at(end) == QLatin1Char('_')))
            return false;
        m_pos = end;
        return true;
    }

    // Consumes `c` (after optional whitespace); leaves the position untouched
    // when it does not match, so a line break ending a statement is kept.
    bool symbol(QChar c)
    {
        const qsizetype saved = m_pos;
        skipSpace();
        if (!atEnd() && m_text.at(m_pos) == c) {
            ++m_pos;
            return true;
        }
        m_pos = saved;
        return false;
    }

    QString identifier()
    {
        skipSpace();
        const bool quoted = !atEnd() && m_text.at(m_pos) == QLatin1Char('`');
        if (quoted)
            ++m_pos;
        const int start = m_pos;
        while (!atEnd() && (m_text.at(m_pos).isLetterOrNumber() || m_text.at(m_pos) == QLatin1Char('_')))
            ++m_pos;
        const QString id = m_text.mid(start, m_pos - start);
        if (quoted && !atEnd() && m_text.at(m_pos) == QLatin1Char('`'))
            ++m_pos;
        return id;
    }

    // Reads one value; returns false on a syntax error.
    bool value(QVariant *out, const QString &nowStamp)
    {
        skipSpace();
        if (atEnd())
            return false;
        const QChar c = m_text.at(m_pos);
        if (c == QLatin1Char('"') || c == QLatin1Char('\'')) {
            ++m_pos;
            QString s;
            while (!atEnd()) {
                const QChar ch = m_text.at(m_pos++);
                if (ch == QLatin1Char('\\') && !atEnd()) {
                    const QChar esc = m_text.at(m_pos++);
                    switch (esc.unicode()) {
                    case 'n': s += QLatin1Char('\n'); break;
                    case 'r': s += QLatin1Char('\r'); break;
                    case 't': s += QLatin1Char('\t'); break;
                    case '0': s += QChar(0); break;
                    case 'Z': s += QChar(26); break;
                    default: s += esc; break;
                    }
                } else if (ch == c) {
                    if (!atEnd() && m_text.at(m_pos) == c) { // doubled quote
                        s += c;
                        ++m_pos;
                    } else {
                        *out = s;
                        return true;
                    }
                } else {
                    s += ch;
                }
            }
            return false; // unterminated string
        }
        const int start = m_pos;
        int depth = 0;
        while (!atEnd()) {
            const QChar ch = m_text.at(m_pos);
            if (ch == QLatin1Char('('))
                ++depth;
            else if (ch == QLatin1Char(')')) {
                if (depth == 0)
                    break;
                --depth;
            } else if (ch == QLatin1Char(',') && depth == 0)
                break;
            ++m_pos;
        }
        const QString token = m_text.mid(start, m_pos - start).trimmed();
        if (token.compare(QLatin1String("NULL"), Qt::CaseInsensitive) == 0)
            *out = QVariant();
        else if (token.compare(QLatin1String("NOW()"), Qt::CaseInsensitive) == 0)
            *out = nowStamp;
        else
            *out = token;
        return !token.isEmpty();
    }

    // Skips to the end of the current statement (a newline or ';' outside quotes).
    void skipStatement()
    {
        QChar quote;
        while (!atEnd()) {
            const QChar ch = m_text.at(m_pos++);
            if (!quote.isNull()) {
                if (ch == QLatin1Char('\\'))
                    ++m_pos;
                else if (ch == quote)
                    quote = QChar();
            } else if (ch == QLatin1Char('"') || ch == QLatin1Char('\'')) {
                quote = ch;
            } else if (ch == QLatin1Char('\n') || ch == QLatin1Char(';')) {
                return;
            }
        }
    }

    int line() const { return int(m_text.left(m_pos).count(QLatin1Char('\n'))) + 1; }

private:
    const QString &m_text;
    qsizetype m_pos = 0;
};

bool execQuery(QSqlQuery &q, QStringList *errors)
{
    if (q.exec())
        return true;
    errors->append(q.lastError().text());
    return false;
}

} // namespace

namespace BakImport {

QString Result::summary() const
{
    static const QMap<QString, QString> names = {
        {QStringLiteral("sp"), QStringLiteral("Sportler")},
        {QStringLiteral("te"), QStringLiteral("Trainingseinheiten")},
        {QStringLiteral("te_ueb"), QStringLiteral("Übungen")},
        {QStringLiteral("wo"), QStringLiteral("Wochen")},
        {QStringLiteral("normen"), QStringLiteral("Normen")},
        {QStringLiteral("spinfo"), QStringLiteral("Sportlerinfos")},
        {QStringLiteral("wk"), QStringLiteral("Wettkämpfe")},
        {QStringLiteral("maz"), QStringLiteral("MAZ")},
        {QStringLiteral("maz_sp"), QStringLiteral("MAZ-Sportler")},
        {QStringLiteral("ueb"), QStringLiteral("ITP/RO-Werte")},
        {QStringLiteral("itp_ls"), QStringLiteral("ITP-Laststufen")},
    };
    QStringList lines;
    for (auto it = tables.cbegin(); it != tables.cend(); ++it) {
        const TableCount &c = it.value();
        lines.append(QStringLiteral("%1: %2 neu, %3 aktualisiert, %4 entfernt, %5 unverändert")
                         .arg(names.value(it.key(), it.key()))
                         .arg(c.added)
                         .arg(c.updated)
                         .arg(c.removed)
                         .arg(c.skipped));
    }
    if (ignoredStatements > 0)
        lines.append(QStringLiteral("%1 Anweisungen übersprungen").arg(ignoredStatements));
    for (const QString &e : errors.mid(0, 10))
        lines.append(QStringLiteral("Fehler: ") + e);
    if (errors.size() > 10)
        lines.append(QStringLiteral("… und %1 weitere Fehler").arg(errors.size() - 10));
    return lines.join(QLatin1Char('\n'));
}

QString decode(const QByteArray &bytes)
{
    // Windows-1252 differs from Latin-1 only in 0x80-0x9F.
    static const char16_t cp1252[32] = {
        0x20AC, 0xFFFD, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
        0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0xFFFD, 0x017D, 0xFFFD,
        0xFFFD, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
        0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0xFFFD, 0x017E, 0x0178};
    QString out;
    out.reserve(bytes.size());
    for (const char ch : bytes) {
        const uchar b = uchar(ch);
        out.append(b >= 0x80 && b < 0xA0 ? QChar(cp1252[b - 0x80]) : QChar(b));
    }
    return out;
}

QList<Row> parse(const QString &text, int *ignoredStatements, QStringList *errors)
{
    QList<Row> rows;
    int ignored = 0;
    QStringList errs;
    const QString nowStamp = Database::now();

    Scanner sc(text);
    while (true) {
        sc.skipSpace();
        if (sc.atEnd())
            break;
        const int line = sc.line();
        bool isInsert = false;
        if (sc.keyword(QStringLiteral("INSERT"))) {
            sc.keyword(QStringLiteral("IGNORE"));
            isInsert = sc.keyword(QStringLiteral("INTO"));
        } else if (sc.keyword(QStringLiteral("REPLACE"))) {
            isInsert = sc.keyword(QStringLiteral("INTO"));
        }
        if (!isInsert) {
            // DELETE statements only guard the following INSERT; the merge
            // by timestamp below does the same job.
            if (!sc.keyword(QStringLiteral("DELETE")))
                ++ignored;
            sc.skipStatement();
            continue;
        }
        const QString table = sc.identifier();
        if (table.isEmpty() || !sc.keyword(QStringLiteral("VALUES"))) {
            errs.append(QStringLiteral("Zeile %1: unbekanntes Format").arg(line));
            sc.skipStatement();
            continue;
        }
        bool ok = true;
        do {
            if (!sc.symbol(QLatin1Char('('))) {
                ok = false;
                break;
            }
            Row row;
            row.table = table.toLower();
            do {
                QVariant v;
                if (!sc.value(&v, nowStamp)) {
                    ok = false;
                    break;
                }
                row.values.append(v);
            } while (sc.symbol(QLatin1Char(',')));
            if (!ok || !sc.symbol(QLatin1Char(')'))) {
                ok = false;
                break;
            }
            rows.append(row);
        } while (sc.symbol(QLatin1Char(',')));
        if (!ok)
            errs.append(QStringLiteral("Zeile %1: Werte nicht lesbar").arg(line));
        sc.skipStatement();
    }
    if (ignoredStatements)
        *ignoredStatements = ignored;
    if (errors)
        *errors += errs;
    return rows;
}

Result importText(const QString &text, bool ignoreTimestamps)
{
    Result r;
    const QList<Row> rows = parse(text, &r.ignoredStatements, &r.errors);

    QSqlDatabase d = QSqlDatabase::database();
    d.transaction();
    for (const Row &row : rows) {
        const TableSpec *spec = Tables::find(row.table);
        if (!spec) {
            ++r.ignoredStatements;
            continue;
        }
        if (row.values.size() != spec->columns.size()) {
            r.errors.append(QStringLiteral("%1: %2 Werte statt %3")
                                .arg(row.table)
                                .arg(row.values.size())
                                .arg(spec->columns.size()));
            continue;
        }
        QVariantMap v;
        for (int i = 0; i < spec->columns.size(); ++i)
            v.insert(spec->columns[i], row.values[i]);
        if (v.contains(QStringLiteral("art")) && !v.value(QStringLiteral("art")).isValid())
            v.insert(QStringLiteral("art"), 0);

        TableCount &count = r.tables[spec->name];
        QStringList where;
        for (const QString &k : spec->keys)
            where.append(k + QStringLiteral(" = ?"));
        const QString whereSql = where.join(QStringLiteral(" AND "));

        QSqlQuery sel(d);
        sel.prepare(QStringLiteral("SELECT korrektur FROM %1 WHERE %2").arg(spec->name, whereSql));
        for (const QString &k : spec->keys)
            sel.addBindValue(v.value(k));
        if (!execQuery(sel, &r.errors))
            continue;
        const bool exists = sel.next();
        const QString incoming = v.value(QStringLiteral("korrektur")).toString();
        // Same or newer local row: nothing to do (also makes re-imports no-ops).
        if (exists && !ignoreTimestamps && sel.value(0).toString() >= incoming) {
            ++count.skipped;
            continue;
        }

        if (v.value(QStringLiteral("del")).toString() == QLatin1String("Y")) {
            if (exists) {
                QVariantList key;
                for (const QString &k : spec->keys)
                    key.append(v.value(k));
                if (Database::deleteRows(spec->name, whereSql, key, incoming))
                    ++count.removed;
                else
                    r.errors.append(Database::lastError());
            } else {
                ++count.skipped;
            }
            continue;
        }

        QStringList marks;
        for (int i = 0; i < spec->stored.size(); ++i)
            marks.append(QStringLiteral("?"));
        QSqlQuery ins(d);
        ins.prepare(QStringLiteral("INSERT OR REPLACE INTO %1 (%2) VALUES (%3)")
                        .arg(spec->name, spec->stored.join(QStringLiteral(", ")),
                             marks.join(QStringLiteral(", "))));
        for (const QString &c : spec->stored)
            ins.addBindValue(v.value(c));
        if (execQuery(ins, &r.errors)) {
            if (exists)
                ++count.updated;
            else
                ++count.added;
        }
    }
    r.ok = d.commit();
    if (!r.ok)
        r.errors.append(d.lastError().text());
    return r;
}

Result importFile(const QString &path, bool ignoreTimestamps)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        Result r;
        r.errors.append(QStringLiteral("Datei kann nicht gelesen werden: ") + f.errorString());
        return r;
    }
    return importText(decode(f.readAll()), ignoreTimestamps);
}

} // namespace BakImport
