#include "report.h"

#include <QFontMetricsF>
#include <QPagedPaintDevice>
#include <QPainter>

namespace Report {

Cells cells(const QStringList &texts)
{
    Cells row;
    row.reserve(texts.size());
    for (const QString &t : texts)
        row.append(Cell{t});
    return row;
}

void Document::heading(const QString &text)
{
    blocks.append(Block{Block::Heading, text, {}});
}

void Document::note(const QString &text)
{
    blocks.append(Block{Block::Note, text, {}});
}

void Document::table(const QList<Cells> &rows)
{
    blocks.append(Block{Block::Table, {}, rows});
}

namespace {

const QString kHeading = QStringLiteral("heading");
const QString kNote = QStringLiteral("note");
const QString kTable = QStringLiteral("table");

} // namespace

QVariantMap toVariant(const Document &d)
{
    QVariantList blocks;
    for (const Block &b : d.blocks) {
        QVariantMap m;
        m.insert(QStringLiteral("kind"), b.kind == Block::Heading ? kHeading : b.kind == Block::Note ? kNote : kTable);
        if (b.kind == Block::Table) {
            QVariantList rows;
            rows.reserve(b.rows.size());
            for (const Cells &r : b.rows) {
                QVariantList row;
                row.reserve(r.size());
                for (const Cell &c : r) {
                    QVariantMap cell{{QStringLiteral("t"), c.text}};
                    if (c.bold)
                        cell.insert(QStringLiteral("b"), true);
                    if (c.muted)
                        cell.insert(QStringLiteral("m"), true);
                    row.append(cell);
                }
                rows.append(QVariant(row));
            }
            m.insert(QStringLiteral("rows"), rows);
        } else {
            m.insert(QStringLiteral("text"), b.text);
        }
        blocks.append(m);
    }
    return {{QStringLiteral("title"), d.title}, {QStringLiteral("blocks"), blocks}};
}

Document fromVariant(const QVariantMap &v)
{
    Document d;
    d.title = v.value(QStringLiteral("title")).toString();
    for (const QVariant &bv : v.value(QStringLiteral("blocks")).toList()) {
        const QVariantMap m = bv.toMap();
        const QString kind = m.value(QStringLiteral("kind")).toString();
        if (kind == kTable) {
            QList<Cells> rows;
            for (const QVariant &rv : m.value(QStringLiteral("rows")).toList()) {
                Cells row;
                for (const QVariant &cv : rv.toList()) {
                    const QVariantMap c = cv.toMap();
                    row.append(Cell{c.value(QStringLiteral("t")).toString(), c.value(QStringLiteral("b")).toBool(),
                                    c.value(QStringLiteral("m")).toBool()});
                }
                rows.append(row);
            }
            d.table(rows);
        } else if (kind == kHeading) {
            d.heading(m.value(QStringLiteral("text")).toString());
        } else {
            d.note(m.value(QStringLiteral("text")).toString());
        }
    }
    return d;
}

namespace {

QFont font(double pt, bool bold = false)
{
    // Inter comes with the program (see main.cpp); Arial etc. if it is missing
    QFont f;
    f.setFamilies({QStringLiteral("Inter"), QStringLiteral("Arial")});
    f.setStyleHint(QFont::SansSerif);
    f.setPointSizeF(pt);
    f.setBold(bold);
    return f;
}

// The colours of the first reports
const QColor kText(0x2a, 0x2a, 0x2a);
const QColor kNoteText(0x6b, 0x65, 0x60);
const QColor kMuted(0xa3, 0x9d, 0x98);
const QColor kLine(0x80, 0x80, 0x80);
const QColor kHeader(0xf1, 0xef, 0xed);

class Painter
{
public:
    Painter(QPagedPaintDevice *device) : m_device(device), m_p(device)
    {
        m_mm = device->logicalDpiY() / 25.4;
        m_width = device->width();
        m_height = device->height();
    }

    double mm(double v) const { return v * m_mm; }

    // A new page when `needed` does not fit below any more
    bool ensure(double needed)
    {
        if (m_y + needed <= m_height || m_y <= 0)
            return false;
        m_device->newPage();
        m_y = 0;
        return true;
    }

    void title(const QString &text)
    {
        const QFont f = font(13, true);
        line(f, kText, text, 0, mm(1.5));
    }

    void heading(const QString &text)
    {
        const QFont f = font(10.5, true);
        // Kept with the start of what it heads: its height and two rows
        ensure(mm(3.5) + QFontMetricsF(f, m_device).height() + mm(10));
        line(f, kText, text, m_y > 0 ? mm(3.5) : 0, mm(1));
    }

    void note(const QString &text)
    {
        const QFont f = font(9);
        const QRectF box = QFontMetricsF(f, m_device)
                               .boundingRect(QRectF(0, 0, m_width, 1e6), Qt::TextWordWrap, text);
        ensure(box.height());
        m_p.setFont(f);
        m_p.setPen(kNoteText);
        m_p.drawText(QRectF(0, m_y, m_width, box.height()), Qt::TextWordWrap, text);
        m_y += box.height() + mm(0.7);
    }

    void table(const QList<Cells> &rows)
    {
        if (rows.isEmpty())
            return;
        const QFont body = font(9);
        const QFont bold = font(9, true);
        const QFontMetricsF fm(body, m_device);
        const QFontMetricsF fmBold(bold, m_device);
        const double padX = mm(0.8);
        const double padY = mm(0.5);
        int columns = 0;
        for (const Cells &r : rows)
            columns = qMax(columns, int(r.size()));
        QList<double> widths(columns, 0);
        for (int i = 0; i < rows.size(); ++i) {
            for (int c = 0; c < rows[i].size(); ++c) {
                const Cell &cell = rows[i][c];
                const bool b = i == 0 || cell.bold;
                widths[c] = qMax(widths[c], (b ? fmBold : fm).horizontalAdvance(cell.text) + 2 * padX);
            }
        }
        double total = 0;
        for (double w : widths)
            total += w;
        const double rowH = fmBold.height() + 2 * padY;
        // Narrowed to the page: drawn smaller as a whole
        const double scale = total > m_width ? m_width / total : 1.0;
        ensure(2 * rowH * scale);

        auto drawRow = [&](const Cells &row, bool header) {
            double x = 0;
            const double y = m_y / scale;
            for (int c = 0; c < columns; ++c) {
                const QRectF box(x, y, widths[c], rowH);
                if (header)
                    m_p.fillRect(box, kHeader);
                if (c < row.size() && !row[c].text.isEmpty()) {
                    const Cell &cell = row[c];
                    m_p.setFont(header || cell.bold ? bold : body);
                    m_p.setPen(cell.muted ? kMuted : kText);
                    m_p.drawText(box.adjusted(padX, 0, -padX, 0),
                                 Qt::AlignVCenter | (c == 0 ? Qt::AlignLeft : Qt::AlignRight), cell.text);
                }
                // The lines of neighbouring cells fall on each other, as
                // in a table with collapsed borders
                m_p.setPen(QPen(kLine, mm(0.2) / scale));
                m_p.setBrush(Qt::NoBrush);
                m_p.drawRect(box);
                x += widths[c];
            }
            m_y += rowH * scale;
        };

        m_p.save();
        m_p.scale(scale, scale);
        for (int i = 0; i < rows.size(); ++i) {
            if (i > 0 && ensure(rowH * scale))
                drawRow(rows[0], true); // the header again on the new page
            drawRow(rows[i], i == 0);
        }
        m_p.restore();
        m_y += mm(1);
    }

private:
    void line(const QFont &f, const QColor &color, const QString &text, double before, double after)
    {
        const QFontMetricsF metrics(f, m_device);
        m_y += before;
        ensure(metrics.height());
        m_p.setFont(f);
        m_p.setPen(color);
        m_p.drawText(QRectF(0, m_y, m_width, metrics.height()), Qt::AlignLeft | Qt::AlignVCenter, text);
        m_y += metrics.height() + after;
    }

    QPagedPaintDevice *m_device;
    QPainter m_p;
    double m_mm = 1;
    double m_width = 0;
    double m_height = 0;
    double m_y = 0;
};

} // namespace

void paint(QPagedPaintDevice *device, const Document &d)
{
    Painter p(device);
    if (!d.title.isEmpty())
        p.title(d.title);
    for (const Block &b : d.blocks) {
        if (b.kind == Block::Heading)
            p.heading(b.text);
        else if (b.kind == Block::Note)
            p.note(b.text);
        else
            p.table(b.rows);
    }
}

} // namespace Report
