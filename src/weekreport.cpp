#include "weekreport.h"

#include <QFontMetricsF>
#include <QImage>
#include <QPageLayout>
#include <QPainter>
#include <QPdfWriter>

#include <functional>

namespace {

using Options = WeekReport::Options;

class Page
{
public:
    Page(QPagedPaintDevice *device, QPainter *painter, std::function<void()> background)
        : m_device(device), m_p(painter), m_background(std::move(background))
    {
        m_mm = device->logicalDpiY() / 25.4;
        m_width = device->width();
        m_height = device->height();
        m_background();
    }

    double mm(double v) const { return v * m_mm; }
    double width() const { return m_width; }
    double height() const { return m_height; }
    double y = 0;

    // Starts a new page when `needed` does not fit any more.
    void ensure(double needed)
    {
        if (y + needed > m_height && y > 0) {
            m_device->newPage();
            y = 0;
            m_background();
        }
    }

    QPainter *painter() const { return m_p; }

private:
    QPagedPaintDevice *m_device;
    QPainter *m_p;
    std::function<void()> m_background;
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
    if (s.from.isValid()) {
        t += QLatin1Char(' ') + Times::text(s.from);
        if (s.to.isValid())
            t += QStringLiteral("–") + Times::text(s.to);
        t += QStringLiteral(" Uhr");
    }
    if (s.number > 1 || !s.from.isValid())
        t += QStringLiteral(" (%1. TE)").arg(s.number);
    return t;
}

// Draws one step, either as  kg        or as  kg/reps/sets
//                            ── sets
//                            reps
double drawStep(QPainter *p, const Page &pg, const Options &o, double x, const QRectF &row,
                const Step &s)
{
    const QFont big = font(o.fontNormal);
    const QFont small = font(o.fontSmall);
    double w = 0;
    if (o.notation == Options::Slash) {
        QString text = QStringLiteral("%1/%2/%3").arg(s.kg).arg(s.reps).arg(qMax(1, s.sets));
        if (s.failed > 0)
            text += QStringLiteral(" (%1 ug)").arg(s.failed);
        p->setFont(big);
        w = QFontMetricsF(big, p->device()).horizontalAdvance(text);
        p->drawText(QRectF(x, row.top(), w + pg.mm(1), row.height()), Qt::AlignLeft | Qt::AlignVCenter,
                    text);
        return w;
    }

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
    w = fracW;
    const QFontMetricsF sm(small, p->device());
    p->setFont(small);
    if (!sets.isEmpty()) {
        const double sw = sm.horizontalAdvance(sets) + pg.mm(0.8);
        p->drawText(QRectF(x + fracW + pg.mm(0.3), row.top(), sw, row.height()),
                    Qt::AlignLeft | Qt::AlignVCenter, sets);
        w += sw;
    }
    if (s.failed > 0) {
        const QString f = QStringLiteral("(%1 ug)").arg(s.failed);
        p->drawText(QRectF(x + w + pg.mm(0.5), row.top(), sm.horizontalAdvance(f) + pg.mm(1), row.height()),
                    Qt::AlignLeft | Qt::AlignVCenter, f);
        w += sm.horizontalAdvance(f) + pg.mm(1);
    }
    return w;
}

void drawSession(Page &pg, const Options &o, const Session &s)
{
    QPainter *p = pg.painter();
    const double W = pg.width();
    const double cTu = pg.mm(9), cWh = pg.mm(10), cMhg = pg.mm(11), cBw = pg.mm(10);
    const double cContent = W - cTu - cWh - cMhg - cBw;
    const double xContent = cTu, xWh = cTu + cContent, xMhg = xWh + cWh, xBw = xMhg + cMhg;
    const double scale = o.fontNormal / 10.0;
    const double headH = pg.mm(6 * scale);
    const double weightH = pg.mm((o.notation == Options::Slash ? 6.5 : 10) * scale);
    const double textH = pg.mm(6.5 * scale);

    auto rowHeight = [&](const Entry &e) { return e.kind == Entry::Weights ? weightH : textH; };
    double total = headH + o.blankPerSession * textH;
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
        if (o.sessionColor.isValid() && o.sessionColor != Qt::white)
            p->fillRect(QRectF(0, top, W, headH), o.sessionColor);
        drawRowGrid(top, headH);
        p->setFont(font(o.fontNormal - 0.5, true));
        p->drawText(QRectF(0, top, cTu, headH), Qt::AlignCenter, QStringLiteral("TÜ"));
        p->drawText(QRectF(xContent, top, cContent, headH), Qt::AlignCenter, sessionTitle(s));
        p->drawText(QRectF(xWh, top, cWh, headH), Qt::AlignCenter, QStringLiteral("WH"));
        p->drawText(QRectF(xMhg, top, cMhg, headH), Qt::AlignCenter, QStringLiteral("MHG"));
        p->drawText(QRectF(xBw, top, cBw, headH), Qt::AlignCenter, QStringLiteral("BW"));
        pg.y += headH;
    };

    auto nextRow = [&](double h) {
        const double before = pg.y;
        pg.ensure(h);
        if (pg.y < before) // continued on a new page: repeat the header
            drawHeader();
    };

    drawHeader();
    for (const Entry &e : s.entries) {
        const double h = rowHeight(e);
        nextRow(h);
        const double top = pg.y;
        drawRowGrid(top, h);
        p->setFont(font(o.fontNormal, true));
        if (e.kind != Entry::FreeText)
            p->drawText(QRectF(0, top, cTu, h), Qt::AlignCenter, QString::number(e.exercise));

        const QRectF content(xContent + pg.mm(1.5), top + pg.mm(0.6), cContent - pg.mm(3),
                             h - pg.mm(1.2));
        if (e.kind == Entry::Weights) {
            double x = content.left();
            for (const Step &st : e.steps)
                x += drawStep(p, pg, o, x, content, st) + pg.mm(5);
            const Stats stats = e.stats();
            p->setFont(font(o.fontNormal));
            p->drawText(QRectF(xWh, top, cWh, h), Qt::AlignCenter, num(stats.wh));
            p->drawText(QRectF(xMhg, top, cMhg, h), Qt::AlignCenter, num(stats.mhg));
            p->drawText(QRectF(xBw, top, cBw, h), Qt::AlignCenter, num(stats.bw));
        } else {
            p->setFont(font(o.fontNormal));
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
    // Empty rows for notes by hand
    for (int i = 0; i < o.blankPerSession; ++i) {
        nextRow(textH);
        drawRowGrid(pg.y, textH);
        pg.y += textH;
    }
    if (!s.note.isEmpty()) {
        pg.ensure(textH);
        const double top = pg.y;
        p->setPen(QPen(Qt::black, pg.mm(0.25)));
        p->drawRect(QRectF(0, top, W, textH));
        p->setFont(font(o.fontNormal - 0.5, false, true));
        p->drawText(QRectF(pg.mm(1.5), top, W - pg.mm(3), textH),
                    (o.sessionNoteCentered ? Qt::AlignHCenter : Qt::AlignLeft) | Qt::AlignVCenter,
                    s.note.simplified());
        pg.y += textH;
    }
    pg.y += pg.mm(4);
}

void drawSummary(Page &pg, const Options &o, const Week &week)
{
    const WeekSummary sum = week.summary();
    if (sum.groups1to7.isEmpty())
        return;
    QPainter *p = pg.painter();
    const double W = pg.width();
    const double scale = o.fontNormal / 10.0;
    const double lineH = pg.mm(4.5 * scale);
    int maxLines = 0;
    for (const GroupSummary &g : sum.groups)
        maxLines = qMax(maxLines, int(g.exercises.size()));
    const double topH = pg.mm(6.5 * scale);
    const double headH = pg.mm(5.5 * scale);
    const double bodyH = qMax(1, maxLines) * lineH + pg.mm(1.5);
    pg.ensure(topH + headH + bodyH + pg.mm(2));

    p->setPen(QPen(Qt::black, pg.mm(0.25)));
    double top = pg.y;
    p->drawRect(QRectF(0, top, W, topH));
    p->drawLine(QPointF(W / 2, top), QPointF(W / 2, top + topH));
    p->setFont(font(o.fontNormal, true));
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
        p->setFont(font(o.fontSmall, true));
        QString title = QStringLiteral("K%1:").arg(g.group);
        if (g.stats.wh > 0)
            title += QStringLiteral(" %1").arg(g.stats.wh);
        p->drawText(head, Qt::AlignCenter, title);
        p->setFont(font(o.fontSmall - 0.5));
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

QPageLayout Options::pageLayout() const
{
    return QPageLayout(QPageSize(paper),
                       landscape ? QPageLayout::Landscape : QPageLayout::Portrait,
                       QMarginsF(marginLeft, marginTop, marginRight, marginBottom),
                       QPageLayout::Millimeter);
}

void render(QPagedPaintDevice *device, const Week &week, const Header &header, const Options &o)
{
    QPainter painter(device);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);
    QPainter *p = &painter;

    const QImage logo = o.logoPath.isEmpty() ? QImage() : QImage(o.logoPath);
    Page pg(device, &painter, [&]() {
        if (logo.isNull())
            return;
        // Faintly in the middle of the page, at most half its width
        const double w = qMin(double(device->width()) * 0.5, double(logo.width()) * 4);
        const double h = w * logo.height() / qMax(1, logo.width());
        p->save();
        p->setOpacity(0.08);
        p->drawImage(QRectF((device->width() - w) / 2, (device->height() - h) / 2, w, h), logo);
        p->restore();
    });
    const double W = pg.width();

    const double lineH = pg.mm(5.5 * o.fontNormal / 10.0);
    p->setFont(font(o.fontNormal));
    if (!header.trainer.isEmpty())
        p->drawText(QRectF(0, 0, W / 2, lineH), Qt::AlignLeft | Qt::AlignVCenter,
                    QStringLiteral("Trainer: ") + header.trainer);
    p->drawText(QRectF(W / 2, 0, W / 2, lineH), Qt::AlignRight | Qt::AlignVCenter,
                header.organisation);
    pg.y += lineH;

    const double titleH = pg.mm(7 * o.fontLarge / 12.0);
    p->setFont(font(o.fontLarge, true));
    p->drawText(QRectF(0, pg.y, W, titleH), Qt::AlignCenter,
                week.variant == Variant::Plan ? QStringLiteral("WOCHENPLAN")
                                              : QStringLiteral("TRAININGSWOCHE (IST)"));
    pg.y += titleH;

    p->setFont(font(o.fontNormal + 1, true));
    p->drawText(QRectF(0, pg.y, W / 2, lineH), Qt::AlignLeft | Qt::AlignVCenter, header.athleteName);
    p->drawText(QRectF(W / 2, pg.y, W / 2, lineH), Qt::AlignRight | Qt::AlignVCenter,
                QStringLiteral("Woche: ") + Weeks::label(week.monday));
    pg.y += lineH;
    p->setFont(font(o.fontSmall));
    p->drawText(QRectF(W / 2, pg.y, W / 2, pg.mm(4.5)), Qt::AlignRight | Qt::AlignVCenter,
                week.monday.toString(QStringLiteral("dd.MM.")) + QStringLiteral(" – ")
                    + week.monday.addDays(6).toString(QStringLiteral("dd.MM.yyyy")));
    pg.y += pg.mm(6) + o.blankHeader * lineH;

    bool any = false;
    for (const Session &s : week.sessions) {
        if (s.entries.isEmpty() && s.note.isEmpty())
            continue;
        drawSession(pg, o, s);
        any = true;
    }
    if (!any) {
        p->setFont(font(o.fontNormal, false, true));
        p->drawText(QRectF(0, pg.y, W, lineH), Qt::AlignLeft | Qt::AlignVCenter,
                    QStringLiteral("Keine Trainingseinheiten in dieser Woche."));
        pg.y += lineH * 2;
    }

    if (o.figures)
        drawSummary(pg, o, week);

    if (o.weekNote && (!week.note.isEmpty() || week.injured)) {
        QString note = week.note.trimmed();
        if (week.injured)
            note = QStringLiteral("verletzt/krank") + (note.isEmpty() ? QString() : QStringLiteral(" – ") + note);
        note = QStringLiteral("Bemerkung: ") + note;
        p->setFont(font(o.fontNormal));
        const int align = Qt::TextWordWrap | (o.weekNoteCentered ? Qt::AlignHCenter : Qt::AlignLeft);
        const QRectF needed = p->boundingRect(QRectF(0, pg.y, W, pg.mm(60)), align, note);
        pg.ensure(needed.height() + pg.mm(2));
        p->drawText(QRectF(0, pg.y, W, needed.height()), align, note);
        pg.y += needed.height() + pg.mm(2);
    }
    // Empty lines with rules, for notes by hand
    p->setPen(QPen(Qt::gray, pg.mm(0.2)));
    for (int i = 0; i < o.blankAfterNote; ++i) {
        pg.ensure(lineH * 1.4);
        pg.y += lineH * 1.4;
        p->drawLine(QPointF(0, pg.y), QPointF(W, pg.y));
    }
}

bool writePdf(const QString &path, const Week &week, const Header &header, const Options &options)
{
    QPdfWriter writer(path);
    writer.setResolution(300);
    writer.setTitle(QStringLiteral("Wochenplan %1 %2").arg(header.athleteName, Weeks::label(week.monday)));
    writer.setCreator(QStringLiteral("Trainingsplaner"));
    writer.setPageLayout(options.pageLayout());
    render(&writer, week, header, options);
    return true;
}

} // namespace WeekReport
