#include "weekreport.h"

#include <QFontMetricsF>
#include <QPageLayout>
#include <QPainter>
#include <QPdfWriter>

namespace {

class Page
{
public:
    Page(QPagedPaintDevice *device, QPainter *painter)
        : m_device(device), m_p(painter)
    {
        m_mm = device->logicalDpiY() / 25.4;
        m_width = device->width();
        m_height = device->height();
    }

    double mm(double v) const { return v * m_mm; }
    double width() const { return m_width; }
    double y = 0;

    // Starts a new page when `needed` does not fit any more.
    void ensure(double needed)
    {
        if (y + needed > m_height && y > 0) {
            m_device->newPage();
            y = 0;
        }
    }

    QPainter *painter() const { return m_p; }

private:
    QPagedPaintDevice *m_device;
    QPainter *m_p;
    double m_mm = 1;
    double m_width = 0;
    double m_height = 0;
};

QFont font(double pt, bool bold = false, bool italic = false)
{
    // Inter comes with the program (see main.cpp); Arial etc. if it is missing.
    QFont f;
    f.setFamilies({QStringLiteral("Inter"), QStringLiteral("Arial")});
    f.setStyleHint(QFont::SansSerif);
    f.setPointSizeF(pt);
    f.setBold(bold);
    f.setItalic(italic);
    return f;
}

QString num(int v)
{
    return v > 0 ? QString::number(v) : QString();
}

QString sessionTitle(const Session &s)
{
    QString t = Weeks::dayName(s.day);
    if (!s.from.isEmpty()) {
        t += QLatin1Char(' ') + s.from;
        if (!s.to.isEmpty())
            t += QStringLiteral("–") + s.to;
        t += QStringLiteral(" Uhr");
    }
    if (s.number > 1 || s.from.isEmpty())
        t += QStringLiteral(" (%1. TE)").arg(s.number);
    return t;
}

// Draws one step as  kg
//                    ── sets
//                    reps
double drawStep(QPainter *p, const Page &pg, double x, const QRectF &row, const Step &s)
{
    const QFont big = font(10);
    const QFont small = font(9);
    const QString kg = QString::number(s.kg);
    const QString reps = QString::number(s.reps);
    const QString sets = s.sets > 1 ? QString::number(s.sets) : QString();
    const QFontMetricsF fm(big, p->device());
    const double fracW = qMax(fm.horizontalAdvance(kg), fm.horizontalAdvance(reps)) + pg.mm(1);
    const double mid = row.center().y();

    p->setFont(big);
    p->drawText(QRectF(x, row.top(), fracW, mid - row.top()), Qt::AlignHCenter | Qt::AlignBottom, kg);
    p->drawLine(QPointF(x, mid), QPointF(x + fracW, mid));
    p->drawText(QRectF(x, mid, fracW, row.bottom() - mid), Qt::AlignHCenter | Qt::AlignTop, reps);
    double w = fracW;
    if (!sets.isEmpty()) {
        p->setFont(small);
        const QFontMetricsF sm(small, p->device());
        const double sw = sm.horizontalAdvance(sets) + pg.mm(0.8);
        p->drawText(QRectF(x + fracW + pg.mm(0.3), row.top(), sw, row.height()),
                    Qt::AlignLeft | Qt::AlignVCenter, sets);
        w += sw;
    }
    if (s.failed > 0) {
        p->setFont(small);
        const QString f = QStringLiteral("(%1 ug)").arg(s.failed);
        const QFontMetricsF sm(small, p->device());
        p->drawText(QRectF(x + w + pg.mm(0.5), row.top(), sm.horizontalAdvance(f) + pg.mm(1), row.height()),
                    Qt::AlignLeft | Qt::AlignVCenter, f);
        w += sm.horizontalAdvance(f) + pg.mm(1);
    }
    return w;
}

void drawSession(Page &pg, const Session &s)
{
    QPainter *p = pg.painter();
    const double W = pg.width();
    const double cTu = pg.mm(9), cWh = pg.mm(10), cMhg = pg.mm(11), cBw = pg.mm(10);
    const double cContent = W - cTu - cWh - cMhg - cBw;
    const double xContent = cTu, xWh = cTu + cContent, xMhg = xWh + cWh, xBw = xMhg + cMhg;
    const double headH = pg.mm(6), weightH = pg.mm(10), textH = pg.mm(6.5);

    auto rowHeight = [&](const Entry &e) { return e.kind == Entry::Weights ? weightH : textH; };
    double total = headH;
    for (const Entry &e : s.entries)
        total += rowHeight(e);
    if (!s.note.isEmpty())
        total += textH;
    // Keep a small session together; a long one may break between rows.
    pg.ensure(qMin(total, headH + weightH * 3) + pg.mm(4));

    auto drawRowGrid = [&](double top, double h) {
        p->setPen(QPen(Qt::black, pg.mm(0.25)));
        p->drawRect(QRectF(0, top, W, h));
        for (double x : {xContent, xWh, xMhg, xBw})
            p->drawLine(QPointF(x, top), QPointF(x, top + h));
    };

    auto drawHeader = [&]() {
        const double top = pg.y;
        drawRowGrid(top, headH);
        p->setFont(font(9.5, true));
        p->drawText(QRectF(0, top, cTu, headH), Qt::AlignCenter, QStringLiteral("TÜ"));
        p->drawText(QRectF(xContent, top, cContent, headH), Qt::AlignCenter, sessionTitle(s));
        p->drawText(QRectF(xWh, top, cWh, headH), Qt::AlignCenter, QStringLiteral("WH"));
        p->drawText(QRectF(xMhg, top, cMhg, headH), Qt::AlignCenter, QStringLiteral("MHG"));
        p->drawText(QRectF(xBw, top, cBw, headH), Qt::AlignCenter, QStringLiteral("BW"));
        pg.y += headH;
    };

    drawHeader();
    for (const Entry &e : s.entries) {
        const double h = rowHeight(e);
        const double before = pg.y;
        pg.ensure(h);
        if (pg.y < before) // continued on a new page: repeat the header
            drawHeader();
        const double top = pg.y;
        drawRowGrid(top, h);
        p->setFont(font(10, true));
        if (e.kind != Entry::FreeText)
            p->drawText(QRectF(0, top, cTu, h), Qt::AlignCenter, QString::number(e.exercise));

        const QRectF content(xContent + pg.mm(1.5), top + pg.mm(0.6), cContent - pg.mm(3),
                             h - pg.mm(1.2));
        if (e.kind == Entry::Weights) {
            double x = content.left();
            for (const Step &st : e.steps)
                x += drawStep(p, pg, x, content, st) + pg.mm(5);
            const Stats stats = e.stats();
            p->setFont(font(10));
            p->drawText(QRectF(xWh, top, cWh, h), Qt::AlignCenter, num(stats.wh));
            p->drawText(QRectF(xMhg, top, cMhg, h), Qt::AlignCenter, num(stats.mhg));
            p->drawText(QRectF(xBw, top, cBw, h), Qt::AlignCenter, num(stats.bw));
        } else {
            p->setFont(font(10));
            QString text = e.text;
            if (e.kind == Entry::ExerciseText) {
                const QString name = Catalog::name(e.exercise);
                text = text.isEmpty() ? name : name + QStringLiteral(": ") + text;
                p->drawText(QRectF(xWh, top, cWh, h), Qt::AlignCenter, num(e.totalReps));
            }
            p->drawText(content, Qt::AlignLeft | Qt::AlignVCenter,
                        QFontMetricsF(p->font(), p->device())
                            .elidedText(text, Qt::ElideRight, content.width()));
        }
        pg.y += h;
    }
    if (!s.note.isEmpty()) {
        pg.ensure(textH);
        const double top = pg.y;
        p->setPen(QPen(Qt::black, pg.mm(0.25)));
        p->drawRect(QRectF(0, top, W, textH));
        p->setFont(font(9.5, false, true));
        p->drawText(QRectF(pg.mm(1.5), top, W - pg.mm(3), textH), Qt::AlignLeft | Qt::AlignVCenter,
                    s.note.simplified());
        pg.y += textH;
    }
    pg.y += pg.mm(4);
}

void drawSummary(Page &pg, const Week &week)
{
    const WeekSummary sum = week.summary();
    if (sum.groups1to7.isEmpty())
        return;
    QPainter *p = pg.painter();
    const double W = pg.width();
    const double lineH = pg.mm(4.5);
    int maxLines = 0;
    for (const GroupSummary &g : sum.groups)
        maxLines = qMax(maxLines, int(g.exercises.size()));
    const double topH = pg.mm(6.5);
    const double headH = pg.mm(5.5);
    const double bodyH = qMax(1, maxLines) * lineH + pg.mm(1.5);
    pg.ensure(topH + headH + bodyH + pg.mm(2));

    p->setPen(QPen(Qt::black, pg.mm(0.25)));
    double top = pg.y;
    p->drawRect(QRectF(0, top, W, topH));
    p->drawLine(QPointF(W / 2, top), QPointF(W / 2, top + topH));
    p->setFont(font(10, true));
    p->drawText(QRectF(pg.mm(2), top, W / 2 - pg.mm(4), topH), Qt::AlignLeft | Qt::AlignVCenter,
                QStringLiteral("K1-7: ") + sum.groups1to7.summary());
    p->drawText(QRectF(W / 2 + pg.mm(2), top, W / 2 - pg.mm(4), topH),
                Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("K1-5: ") + sum.groups1to5.summary());
    top += topH;

    const double colW = W / Catalog::summaryGroups;
    p->drawRect(QRectF(0, top, W, headH));
    p->drawRect(QRectF(0, top + headH, W, bodyH));
    for (int i = 1; i < Catalog::summaryGroups; ++i)
        p->drawLine(QPointF(colW * i, top), QPointF(colW * i, top + headH + bodyH));
    for (int i = 0; i < Catalog::summaryGroups; ++i) {
        const GroupSummary &g = sum.groups[i];
        const QRectF head(colW * i, top, colW, headH);
        p->setFont(font(9, true));
        QString title = QStringLiteral("K%1:").arg(g.group);
        if (g.stats.wh > 0)
            title += QStringLiteral(" %1").arg(g.stats.wh);
        p->drawText(head, Qt::AlignCenter, title);
        p->setFont(font(8.5));
        double y = top + headH + pg.mm(0.8);
        for (const ExerciseSummary &ex : g.exercises) {
            const QString line = QStringLiteral("%1  %2  %3  %4  %5")
                                     .arg(ex.exercise)
                                     .arg(ex.stats.wh)
                                     .arg(ex.stats.mhg)
                                     .arg(ex.stats.bw)
                                     .arg(ex.stats.bwRepsSets());
            p->drawText(QRectF(colW * i, y, colW, lineH), Qt::AlignCenter, line);
            y += lineH;
        }
    }
    pg.y = top + headH + bodyH + pg.mm(4);
}

} // namespace

namespace WeekReport {

void render(QPagedPaintDevice *device, const Week &week, const Header &header)
{
    QPainter painter(device);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);
    Page pg(device, &painter);
    QPainter *p = &painter;
    const double W = pg.width();

    const double lineH = pg.mm(5.5);
    p->setFont(font(10));
    if (!header.trainer.isEmpty())
        p->drawText(QRectF(0, 0, W / 2, lineH), Qt::AlignLeft | Qt::AlignVCenter,
                    QStringLiteral("Trainer: ") + header.trainer);
    p->drawText(QRectF(W / 2, 0, W / 2, lineH), Qt::AlignRight | Qt::AlignVCenter,
                header.organisation);
    pg.y += lineH;

    p->setFont(font(12, true));
    p->drawText(QRectF(0, pg.y, W, pg.mm(7)), Qt::AlignCenter,
                week.variant == Variant::Plan ? QStringLiteral("WOCHENPLAN")
                                              : QStringLiteral("TRAININGSWOCHE (IST)"));
    pg.y += pg.mm(7);

    p->setFont(font(11, true));
    p->drawText(QRectF(0, pg.y, W / 2, lineH), Qt::AlignLeft | Qt::AlignVCenter, header.athleteName);
    p->drawText(QRectF(W / 2, pg.y, W / 2, lineH), Qt::AlignRight | Qt::AlignVCenter,
                QStringLiteral("Woche: ") + Weeks::label(week.monday));
    pg.y += lineH;
    p->setFont(font(9));
    p->drawText(QRectF(W / 2, pg.y, W / 2, pg.mm(4.5)), Qt::AlignRight | Qt::AlignVCenter,
                week.monday.toString(QStringLiteral("dd.MM.")) + QStringLiteral(" – ")
                    + week.monday.addDays(6).toString(QStringLiteral("dd.MM.yyyy")));
    pg.y += pg.mm(6);

    bool any = false;
    for (const Session &s : week.sessions) {
        if (s.entries.isEmpty() && s.note.isEmpty())
            continue;
        drawSession(pg, s);
        any = true;
    }
    if (!any) {
        p->setFont(font(10, false, true));
        p->drawText(QRectF(0, pg.y, W, lineH), Qt::AlignLeft | Qt::AlignVCenter,
                    QStringLiteral("Keine Trainingseinheiten in dieser Woche."));
        pg.y += lineH * 2;
    }

    drawSummary(pg, week);

    if (!week.note.isEmpty() || week.injured) {
        QString note = week.note.trimmed();
        if (week.injured)
            note = QStringLiteral("verletzt/krank") + (note.isEmpty() ? QString() : QStringLiteral(" – ") + note);
        p->setFont(font(10));
        const QRectF box(0, pg.y, W, pg.mm(40));
        const QRectF needed = p->boundingRect(box, Qt::TextWordWrap, QStringLiteral("Bemerkung: ") + note);
        pg.ensure(needed.height() + pg.mm(2));
        p->drawText(QRectF(0, pg.y, W, needed.height()), Qt::TextWordWrap,
                    QStringLiteral("Bemerkung: ") + note);
        pg.y += needed.height() + pg.mm(2);
    }
}

bool writePdf(const QString &path, const Week &week, const Header &header)
{
    QPdfWriter writer(path);
    writer.setResolution(300);
    writer.setTitle(QStringLiteral("Wochenplan %1 %2").arg(header.athleteName, Weeks::label(week.monday)));
    writer.setCreator(QStringLiteral("Trainingsplaner"));
    writer.setPageLayout(QPageLayout(QPageSize(QPageSize::A4), QPageLayout::Portrait,
                                     QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter));
    render(&writer, week, header);
    return true;
}

} // namespace WeekReport
