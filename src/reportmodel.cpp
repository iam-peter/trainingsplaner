#include "reportmodel.h"

#include <QFontMetricsF>

#include <cmath>

namespace {

// Room beside and above the text of a cell, as the first reports had it
constexpr qreal kPadX = 3;
constexpr qreal kPadY = 3;

} // namespace

ReportModel::ReportModel(QObject *parent) : QAbstractTableModel(parent) {}

void ReportModel::setReport(const QVariantMap &report)
{
    if (report == m_report)
        return;
    m_report = report;
    rebuild();
    emit reportChanged();
}

void ReportModel::setFont(const QFont &font)
{
    if (font == m_font)
        return;
    m_font = font;
    // Only the sizes change, not the rows and columns
    measure();
    emit fontChanged();
}

void ReportModel::rebuild()
{
    const Report::Document doc = Report::fromVariant(m_report);
    QList<Line> lines;
    int columns = 1;
    if (!doc.title.isEmpty() && !doc.blocks.isEmpty())
        lines.append(Line{Title, doc.title, {}});
    for (const Report::Block &b : doc.blocks) {
        if (b.kind == Report::Block::Table) {
            int tableColumns = 0;
            for (const Report::Cells &r : b.rows)
                tableColumns = qMax(tableColumns, int(r.size()));
            for (int i = 0; i < b.rows.size(); ++i) {
                Line l{i == 0 ? Header : Cell, {}, b.rows[i]};
                l.columns = tableColumns;
                lines.append(l);
            }
            columns = qMax(columns, tableColumns);
            // Room below the table, before what follows
            lines.append(Line{Blank, {}, {}});
        } else {
            Line l{b.kind == Report::Block::Heading ? Heading : Note, b.text, {}};
            l.lines = int(b.text.count(QLatin1Char('\n'))) + 1;
            lines.append(l);
        }
    }
    beginResetModel();
    m_lines = lines;
    m_columns = columns;
    measure();
    endResetModel();
}

void ReportModel::measure()
{
    QFont bold = m_font;
    bold.setBold(true);
    const QFontMetricsF fm(m_font);
    const QFontMetricsF fmBold(bold);
    m_lineHeight = fmBold.height();
    m_widths = QList<qreal>(m_columns, 0);
    for (const Line &l : std::as_const(m_lines)) {
        for (int c = 0; c < l.cells.size(); ++c) {
            const Report::Cell &cell = l.cells[c];
            if (cell.text.isEmpty())
                continue;
            const qreal w = (l.kind == Header || cell.bold ? fmBold : fm).horizontalAdvance(cell.text);
            m_widths[c] = qMax(m_widths[c], std::ceil(w) + 2 * kPadX);
        }
    }
    // An empty column still shows as a narrow cell
    for (qreal &w : m_widths)
        w = qMax(w, 2 * kPadX + 8);
    emit layoutDone();
}

qreal ReportModel::columnWidth(int column) const
{
    return column >= 0 && column < m_widths.size() ? m_widths[column] : 0;
}

qreal ReportModel::rowHeight(int row) const
{
    if (row < 0 || row >= m_lines.size())
        return 0;
    const qreal h = std::ceil(m_lineHeight);
    switch (m_lines[row].kind) {
    case Title:
        return std::ceil(h * 2.2);
    case Heading:
        // With the room above it that sets it apart from what is before
        return std::ceil(h * 2.4);
    case Note:
        return h * m_lines[row].lines + 6;
    case Blank:
        return 6;
    default:
        return h + 2 * kPadY;
    }
}

qreal ReportModel::totalWidth() const
{
    qreal w = 0;
    for (qreal x : m_widths)
        w += x;
    return w;
}

qreal ReportModel::padding() const
{
    return kPadX;
}

qreal ReportModel::totalHeight() const
{
    qreal h = 0;
    for (int r = 0; r < m_lines.size(); ++r)
        h += rowHeight(r);
    return h;
}

int ReportModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_lines.size());
}

int ReportModel::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_columns;
}

QVariant ReportModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_lines.size())
        return {};
    const Line &l = m_lines[index.row()];
    const int c = index.column();
    const bool inTable = l.kind == Header || l.kind == Cell;
    // Beside a heading or note, and right of a narrower table: nothing
    Kind kind = l.kind;
    if (!inTable && c > 0)
        kind = Blank;
    if (inTable && c >= l.columns)
        kind = Blank;
    switch (role) {
    case Qt::DisplayRole:
        if (inTable)
            return c < l.cells.size() ? l.cells[c].text : QString();
        return c == 0 ? l.text : QString();
    case KindRole:
        return int(kind);
    case BoldRole:
        return l.kind == Header || l.kind == Title || l.kind == Heading
               || (inTable && c < l.cells.size() && l.cells[c].bold);
    case MutedRole:
        return l.kind == Note || (inTable && c < l.cells.size() && l.cells[c].muted);
    case LeftRole:
        return c == 0;
    }
    return {};
}

QHash<int, QByteArray> ReportModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"},
            {KindRole, "kind"},
            {BoldRole, "bold"},
            {MutedRole, "muted"},
            {LeftRole, "alignLeft"}};
}
