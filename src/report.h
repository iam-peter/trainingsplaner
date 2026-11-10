#pragma once

#include <QList>
#include <QString>
#include <QVariant>

class QPagedPaintDevice;

// An analysis report as the program shows, prints and saves it: a title,
// then headings, notes and tables one below the other. The analyses build
// it; QML gets it as a map (toVariant) and shows it as a table view, and
// paint() puts it on paper or into a PDF. Tables look like the program's
// first reports did: thin dark lines, a grey header row, the first column
// left-aligned and the others right.
namespace Report {

struct Cell
{
    QString text;
    bool bold = false;
    bool muted = false; // a week that does not count
};

using Cells = QList<Cell>;

// Cells from plain texts
Cells cells(const QStringList &texts);

struct Block
{
    enum Kind { Heading, Note, Table };
    Kind kind = Note;
    QString text;      // Heading, Note (lines split by \n)
    QList<Cells> rows; // Table: the first row is its header
};

struct Document
{
    QString title;
    QList<Block> blocks;

    void heading(const QString &text);
    void note(const QString &text);
    void table(const QList<Cells> &rows);
};

// {title, blocks: [{kind: "heading" | "note" | "table", text,
//   rows: [[{t, b (bold), m (muted)}]]}]}; b and m only where true
QVariantMap toVariant(const Document &d);
Document fromVariant(const QVariantMap &v);

// The report as text for a spreadsheet: the title, headings and notes a
// line each, every table row a line with its cells separated by tabs, and
// an empty line after each table. Tabs, not commas: the numbers have
// decimal commas (5,5), and spreadsheets split pasted text at tabs.
QString toText(const Document &d);

// The same as a CSV file for German spreadsheets: separated by semicolons
// (as Excel expects them with a decimal comma), quoted where a cell holds
// one, lines ending in CR LF, UTF-8 with a byte order mark so Excel reads
// the umlauts
QByteArray toCsv(const Document &d);

// Paints the report onto a device already set up with its page layout. A
// table wider than the page is drawn smaller; a long one goes on over the
// next page, its header row repeated there.
void paint(QPagedPaintDevice *device, const Document &d);

} // namespace Report
