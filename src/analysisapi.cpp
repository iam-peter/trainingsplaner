#include "analysisapi.h"

#include "analysis.h"
#include "catalog.h"
#include "competition.h"
#include "database.h"
#include "planning.h"
#include "report.h"

#include <QClipboard>
#include <QDesktopServices>
#include <QFile>
#include <QGuiApplication>
#include <QLocale>
#include <QPageLayout>
#include <QPdfWriter>
#include "printpreview.h"

#include <QPrintDialog>
#include <QPrinter>

namespace {

using namespace Analysis;
using Report::Cell;
using Report::Cells;

const QLocale de(QLocale::German);

QString fmt(double v, int decimals = 0, bool sign = false)
{
    if (!has(v))
        return QString();
    QString s = de.toString(v, 'f', decimals);
    if (sign && v > 0)
        s.prepend(QLatin1Char('+'));
    return s;
}

Basis basisFrom(const QString &b)
{
    if (b == QLatin1String("P"))
        return Basis::Plan;
    if (b == QLatin1String("T"))
        return Basis::Itp;
    return Basis::Actual;
}

QString basisName(const QString &b)
{
    if (b == QLatin1String("P"))
        return QStringLiteral("Plan");
    if (b == QLatin1String("T"))
        return QStringLiteral("ITP");
    if (b == QLatin1String("R"))
        return QStringLiteral("RO");
    return QStringLiteral("Ist");
}

Reference referenceFrom(const QString &r)
{
    if (r == QLatin1String("ziel"))
        return Reference::MazTarget;
    if (r == QLatin1String("wk"))
        return Reference::MazCompetition;
    return Reference::Absolute;
}

// The period of a request: a MAZ, or a start week and number of weeks
bool period(const QVariantMap &p, const QString &mazKey, QDate *from, int *weeks, Maz *maz = nullptr)
{
    const QString mazId = p.value(mazKey).toString();
    if (!mazId.isEmpty()) {
        const Maz m = Planning::maz(mazId);
        if (maz)
            *maz = m;
        *from = m.from;
        *weeks = m.weeks();
    } else {
        *from = Weeks::fromLabel(p.value(QStringLiteral("from")).toString());
        *weeks = qBound(0, p.value(QStringLiteral("weeks")).toInt(), 156);
    }
    return from->isValid() && *weeks > 0;
}

QList<Cells> sectionTable(const Section &s, bool summary, bool itp)
{
    const int pr = 1; // decimals for percent values
    QList<Cells> rows;
    Cells head = Report::cells({QStringLiteral("TÜ"), QString()});
    if (!summary) {
        for (int i = 0; i < s.weeks.size(); ++i)
            head.append(Cell{QStringLiteral("%1.").arg(s.weeks[i].weekNumber()), false, bool(s.excluded[i])});
    }
    head += Report::cells({QStringLiteral("1)"), QStringLiteral("2)"), QStringLiteral("3)")});
    rows.append(head);

    for (const Row &r : s.rows) {
        const int d = r.percent ? pr : 0;
        auto line = [&](const QString &label, const QList<double> &weekly, int wd, double a, double b, double c,
                        int ad, int bd, int cd, bool first, bool trend = true) {
            Cells v{Cell{first ? r.name : QString(), true}, Cell{label}};
            if (!summary) {
                for (double x : weekly)
                    v.append(Cell{fmt(x, wd)});
            }
            v += Report::cells({fmt(a, ad), fmt(b, bd), fmt(c, cd, trend)});
            rows.append(v);
        };
        line(QStringLiteral("Wh"), r.wh, 0, r.whTotal, r.whPerWeek, r.whTrend, 0, 1, 1, true);
        line(QStringLiteral("Mhg"), r.mhg, d, r.mhgMax, r.mhgPeriod, r.mhgTrend, d, d, 1, false);
        line(QStringLiteral("BW"), r.bw, d, r.bwMax, r.mhgTop30, r.bwTrend, d, d, 1, false);
        if (!itp)
            line(QStringLiteral("SG"), r.sg, 1, r.sgMean, r.sgTop30, r.failed, 1, 1, 0, false, false);
    }
    return rows;
}

QString legend(bool itp)
{
    QString l = QStringLiteral(
        "Wh: 1) Gesamtumfang; 2) Wh pro Woche; 3) durchschnittlicher Zuwachs von Woche zu Woche (Regression)\n"
        "Mhg: 1) höchstes Wochen-Mhg; 2) Mhg des Abschnitts; 3) durchschnittlicher Zuwachs von Woche zu Woche\n"
        "BW: 1) höchstes BW; 2) Mhg der 30 schwersten Versuche; 3) durchschnittlicher Zuwachs von Woche zu Woche");
    if (!itp)
        l += QStringLiteral("\nSG: 1) mittlere Satzgröße; 2) mittlere Satzgröße der 30 schwersten Versuche; 3) ungültige Versuche");
    return l;
}

QString sectionTitle(const QString &athlete, const QString &what, int weeks, const Section &s,
                     const QString &basis)
{
    return QStringLiteral("%1 – %2 (%3, %4/%5 Wochen, %6 TE)")
        .arg(athlete, what, basis)
        .arg(s.countedWeeks)
        .arg(weeks)
        .arg(fmt(s.sessions));
}
// Framework plan in kg-free form: its own percent values as a section
Section roSection(const QString &mazId, bool groups)
{
    Section s;
    const Maz m = Planning::maz(mazId);
    for (int i = 0; i < m.weeks(); ++i) {
        s.weeks.append(m.from.addDays(7 * i));
        s.excluded.append(false);
    }
    s.countedWeeks = m.weeks();
    QMap<int, Row> rows;
    for (const WeekTarget &t : Planning::targets(Planning::roOwner(mazId), m.from, m.to)) {
        if ((t.exercise < 0) != groups)
            continue;
        Row &r = rows[t.exercise];
        if (r.wh.isEmpty()) {
            r.key = t.exercise;
            r.name = t.exercise < 0 ? QStringLiteral("K%1").arg(-t.exercise)
                                    : QStringLiteral("%1 %2").arg(t.exercise).arg(Catalog::name(t.exercise));
            r.percent = true;
            for (int i = 0; i < m.weeks(); ++i) {
                r.wh.append(none); r.mhg.append(none); r.bw.append(none); r.sg.append(none);
            }
        }
        const int w = int(m.from.daysTo(t.monday) / 7);
        r.wh[w] = t.wh > 0 ? t.wh : none;
        r.mhg[w] = t.mhg > 0 ? t.mhg : none;
        r.bw[w] = t.bw > 0 ? t.bw : none;
    }
    for (Row r : rows) {
        double sum = 0, weighted = 0, mx = none, bmx = none;
        for (int i = 0; i < r.wh.size(); ++i) {
            if (has(r.wh[i])) {
                sum += r.wh[i];
                if (has(r.mhg[i]))
                    weighted += r.wh[i] * r.mhg[i];
            }
            if (has(r.mhg[i]) && (!has(mx) || r.mhg[i] > mx)) mx = r.mhg[i];
            if (has(r.bw[i]) && (!has(bmx) || r.bw[i] > bmx)) bmx = r.bw[i];
        }
        r.whTotal = sum;
        r.whPerWeek = s.countedWeeks ? sum / s.countedWeeks : none;
        r.whTrend = slope(r.wh);
        r.mhgMax = mx;
        r.mhgPeriod = sum > 0 && weighted > 0 ? weighted / sum : none;
        r.mhgTrend = slope(r.mhg);
        r.bwMax = bmx;
        r.bwTrend = slope(r.bw);
        s.rows.append(r);
    }
    return s;
}

void addLoadTable(Report::Document &doc, const LoadTable &t, int exercise)
{
    doc.heading(QStringLiteral("Laststufenanalyse TÜ %1 %2 (Wiederholungen je Gewicht)")
                    .arg(exercise)
                    .arg(Catalog::name(exercise)));
    if (t.kg.isEmpty()) {
        doc.note(QStringLiteral("Keine Daten."));
        return;
    }
    QList<Cells> rows;
    Cells head = Report::cells({QStringLiteral("kg")});
    for (const QDate &w : t.weeks)
        head.append(Cell{QStringLiteral("%1.").arg(w.weekNumber())});
    head.append(Cell{QStringLiteral("ges.")});
    rows.append(head);
    for (int i = 0; i < t.kg.size(); ++i) {
        Cells v{Cell{QString::number(t.kg[i])}};
        for (int r : t.reps[i])
            v.append(Cell{r > 0 ? QString::number(r) : QString()});
        v.append(Cell{QString::number(t.totals[i]), true});
        rows.append(v);
    }
    doc.table(rows);
}

} // namespace

AnalysisApi::AnalysisApi(QObject *parent) : QObject(parent) {}

QVariantMap AnalysisApi::individual(const QVariantMap &p) const
{
    Report::Document doc;
    doc.title = QStringLiteral("Abschnittsanalyse");
    const QString athleteId = p.value(QStringLiteral("athleteId")).toString();
    const Athlete a = Database::athlete(athleteId);
    QDate from;
    int weeks = 0;
    Maz maz;
    if (athleteId.isEmpty() || !period(p, QStringLiteral("mazId"), &from, &weeks, &maz)) {
        doc.note(QStringLiteral("Bitte Sportler und Zeitraum wählen."));
        return Report::toVariant(doc);
    }

    const QString basis = p.value(QStringLiteral("basis")).toString();
    Params params;
    params.athleteId = athleteId;
    params.from = from;
    params.weeks = weeks;
    params.basis = basisFrom(basis);
    params.groups = p.value(QStringLiteral("groups")).toBool();
    params.includeCompetitionWeeks = p.value(QStringLiteral("competitionWeeks")).toBool();
    params.reference = referenceFrom(p.value(QStringLiteral("reference")).toString());
    params.mazId = p.value(QStringLiteral("mazId")).toString();
    const bool summary = p.value(QStringLiteral("summary")).toBool();
    const bool itp = params.basis == Basis::Itp;

    const QString what = maz.id.isEmpty() ? QStringLiteral("Woche %1 bis %2").arg(Weeks::label(from), Weeks::label(from.addDays(7 * (weeks - 1))))
                                          : maz.name;
    const Section s = section(params);
    doc.heading(sectionTitle(a.fullName(), what, weeks, s, basisName(basis)));
    if (params.reference != Reference::Absolute)
        doc.note(QStringLiteral("Mhg und BW in % der %1 im MAZ.")
                     .arg(params.reference == Reference::MazTarget ? QStringLiteral("Zielleistung")
                                                                   : QStringLiteral("Wettkampfleistung")));
    if (s.rows.isEmpty())
        doc.note(QStringLiteral("Keine Daten im Zeitraum."));
    else
        doc.table(sectionTable(s, summary, itp));

    // Comparison with another MAZ
    const QString compareMaz = p.value(QStringLiteral("compareMazId")).toString();
    if (!compareMaz.isEmpty()) {
        const Maz cm = Planning::maz(compareMaz);
        const QString cb = p.value(QStringLiteral("compareBasis")).toString();
        Section cs;
        if (cb == QLatin1String("R")) {
            cs = roSection(compareMaz, params.groups);
        } else {
            Params c = params;
            c.from = cm.from;
            c.weeks = cm.weeks();
            c.basis = basisFrom(cb);
            c.mazId = compareMaz;
            cs = section(c);
        }
        doc.heading(QStringLiteral("Vergleich: %1 (%2)").arg(cm.name, basisName(cb)));
        if (cs.rows.isEmpty())
            doc.note(QStringLiteral("Keine Daten."));
        else
            doc.table(sectionTable(cs, summary, cb == QLatin1String("T") || cb == QLatin1String("R")));
    }

    // Overview of all MAZ of the athlete
    if (p.value(QStringLiteral("allMaz")).toBool()) {
        const QList<Maz> list = Planning::mazForAthlete(athleteId);
        QList<Cells> rows;
        Cells head = Report::cells({QStringLiteral("TÜ")});
        for (const Maz &m : list)
            head += Report::cells({QStringLiteral("%1 Wh").arg(m.shortName.isEmpty() ? m.name : m.shortName),
                                   QStringLiteral("Mhg"), QStringLiteral("BW")});
        rows.append(head);
        QMap<int, QStringList> byKey;
        QMap<int, QString> names;
        for (int i = 0; i < list.size(); ++i) {
            Params c = params;
            c.from = list[i].from;
            c.weeks = list[i].weeks();
            c.mazId = list[i].id;
            for (const Row &r : section(c).rows) {
                QStringList &v = byKey[r.key];
                while (v.size() < i * 3)
                    v.append(QString());
                v << fmt(r.whTotal) << fmt(r.mhgPeriod, r.percent ? 1 : 0) << fmt(r.bwMax, r.percent ? 1 : 0);
                names[r.key] = r.name;
            }
        }
        for (auto it = byKey.begin(); it != byKey.end(); ++it) {
            while (it->size() < list.size() * 3)
                it->append(QString());
            rows.append(Report::cells(QStringList{names.value(it.key())} + *it));
        }
        doc.heading(QStringLiteral("Gesamtübersicht aller MAZ (%1)").arg(basisName(basis)));
        if (list.isEmpty())
            doc.note(QStringLiteral("Der Sportler ist in keinem MAZ."));
        else
            doc.table(rows);
    }

    const int loadEx = p.value(QStringLiteral("loadExercise")).toInt();
    if (loadEx > 0 && !itp) {
        addLoadTable(doc, loadTable(athleteId, params.basis == Basis::Plan ? Variant::Plan : Variant::Actual,
                                    loadEx, from, weeks), loadEx);
    }
    doc.note(legend(itp));
    return Report::toVariant(doc);
}

QVariantMap AnalysisApi::group(const QVariantMap &p) const
{
    Report::Document doc;
    doc.title = QStringLiteral("Gruppenanalyse");
    const QString mazId = p.value(QStringLiteral("mazId")).toString();
    const Maz maz = Planning::maz(mazId);
    if (mazId.isEmpty() || !maz.from.isValid()) {
        doc.note(QStringLiteral("Bitte einen MAZ wählen."));
        return Report::toVariant(doc);
    }
    const int mode = p.value(QStringLiteral("mode")).toInt();
    const Reference ref = referenceFrom(p.value(QStringLiteral("reference")).toString());
    const bool compWeeks = p.value(QStringLiteral("competitionWeeks")).toBool();
    const int exercise = qMax(1, p.value(QStringLiteral("exercise")).toInt());

    QList<Cells> rows;
    if (mode == 0)
        rows.append(Report::cells({QStringLiteral("Sportler"), QStringLiteral("Wochen"), QStringLiteral("TE"),
                                   QStringLiteral("Wh K1-7"), QStringLiteral("Wh/Wo"), QStringLiteral("Mhg K1-7"),
                                   QStringLiteral("t"), QStringLiteral("bester ZK")}));
    else if (mode == 1) {
        QStringList h{QStringLiteral("Sportler")};
        for (int g = 1; g <= 7; ++g)
            h.append(QStringLiteral("K%1").arg(g));
        h.append(QStringLiteral("K1-7"));
        rows.append(Report::cells(h));
    } else {
        rows.append(Report::cells({QStringLiteral("Sportler"), QStringLiteral("Wh"), QStringLiteral("höchstes BW"),
                                   QStringLiteral("Mhg Abschnitt"), QStringLiteral("Mhg 30 schwerste"),
                                   QStringLiteral("Trend BW")}));
    }

    for (const MazAthlete &ma : Planning::mazAthletes(mazId)) {
        Params params;
        params.athleteId = ma.athleteId;
        params.from = maz.from;
        params.weeks = maz.weeks();
        params.includeCompetitionWeeks = compWeeks;
        params.reference = mode == 2 ? ref : Reference::Absolute;
        params.mazId = mazId;
        params.groups = mode != 2;
        const Section s = section(params);
        const QString name = Database::athlete(ma.athleteId).displayName();
        if (mode == 0) {
            double wh = 0, tonnage = 0;
            for (const Row &r : s.rows) {
                wh += has(r.whTotal) ? r.whTotal : 0;
                tonnage += has(r.whTotal) && has(r.mhgPeriod) ? r.whTotal * r.mhgPeriod : 0;
            }
            int best = 0;
            for (const Competition &c : Competitions::between(ma.athleteId, maz.from, maz.to.addDays(6)))
                best = qMax(best, c.total());
            rows.append(Report::cells({name, QString::number(s.countedWeeks), fmt(s.sessions), fmt(wh),
                                       fmt(s.countedWeeks ? wh / s.countedWeeks : none, 1),
                                       fmt(wh > 0 ? tonnage / wh : none), fmt(tonnage / 1000.0, 1),
                                       best > 0 ? QString::number(best) : QString()}));
        } else if (mode == 1) {
            Cells v{Cell{name}};
            double all = 0;
            for (int g = 1; g <= 7; ++g) {
                double perWeek = none;
                for (const Row &r : s.rows) {
                    if (r.key == -g)
                        perWeek = r.whPerWeek;
                }
                v.append(Cell{fmt(perWeek, 1)});
                all += has(perWeek) ? perWeek : 0;
            }
            v.append(Cell{fmt(all, 1), true});
            rows.append(v);
        } else {
            Row r;
            for (const Row &x : s.rows) {
                if (x.key == exercise)
                    r = x;
            }
            const int d = r.percent ? 1 : 0;
            rows.append(Report::cells({name, fmt(r.whTotal), fmt(r.bwMax, d), fmt(r.mhgPeriod, d),
                                       fmt(r.mhgTop30, d), fmt(r.bwTrend, 1, true)}));
        }
    }
    static const char *modes[] = {"Gesamtübersicht", "Umfangskennziffern (Wh pro Woche)", "Intensitätskennziffern"};
    doc.heading(QStringLiteral("%1 – %2, %3 bis %4")
                    .arg(QString::fromUtf8(modes[qBound(0, mode, 2)]), maz.name, Weeks::label(maz.from),
                         Weeks::label(maz.to)));
    if (mode == 2)
        doc.note(QStringLiteral("TÜ %1 %2%3")
                     .arg(exercise)
                     .arg(Catalog::name(exercise))
                     .arg(ref == Reference::Absolute ? QStringLiteral(", kg")
                                                     : ref == Reference::MazTarget ? QStringLiteral(", % der Zielleistung")
                                                                                   : QStringLiteral(", % der Wettkampfleistung")));
    doc.table(rows);
    return Report::toVariant(doc);
}

QVariantMap AnalysisApi::dataCheck(const QVariantMap &p) const
{
    Report::Document doc;
    const QDate from = Weeks::fromLabel(p.value(QStringLiteral("from")).toString());
    const int weeks = qBound(1, p.value(QStringLiteral("weeks")).toInt(), 104);
    const bool competitions = p.value(QStringLiteral("mode")).toInt() == 1;
    doc.title = competitions ? QStringLiteral("Wettkämpfe") : QStringLiteral("Trainingsdaten");
    if (!from.isValid()) {
        doc.note(QStringLiteral("Bitte die erste Woche angeben."));
        return Report::toVariant(doc);
    }
    const QVariantList athletes = p.value(QStringLiteral("athletes")).toList();
    const QString range = QStringLiteral("Woche %1 bis %2.").arg(Weeks::label(from), Weeks::label(from.addDays(7 * (weeks - 1))));
    QList<Cells> rows;
    if (!competitions) {
        QStringList head{QStringLiteral("Sportler")};
        for (int i = 0; i < weeks; ++i)
            head.append(QStringLiteral("%1.").arg(from.addDays(7 * i).weekNumber()));
        rows.append(Report::cells(head));
        for (const QVariant &v : athletes) {
            const QVariantMap a = v.toMap();
            const QString id = a.value(QStringLiteral("id")).toString();
            const QList<int> plan = sessionCounts(id, from, weeks, Variant::Plan);
            const QList<int> actual = sessionCounts(id, from, weeks, Variant::Actual);
            QStringList r{a.value(QStringLiteral("displayName")).toString()};
            for (int i = 0; i < weeks; ++i)
                r.append(plan[i] || actual[i] ? QStringLiteral("%1/%2").arg(plan[i]).arg(actual[i]) : QString());
            rows.append(Report::cells(r));
        }
        doc.note(QStringLiteral("Trainingseinheiten je Woche: Plan/Ist, ") + range);
        doc.table(rows);
        return Report::toVariant(doc);
    }
    rows.append(Report::cells({QStringLiteral("Sportler"), QStringLiteral("Datum"), QStringLiteral("Art"),
                               QStringLiteral("Wettkampf"), QStringLiteral("KG"), QStringLiteral("Reißen"),
                               QStringLiteral("Stoßen"), QStringLiteral("ZK")}));
    for (const QVariant &v : athletes) {
        const QVariantMap a = v.toMap();
        for (const Competition &c : Competitions::between(a.value(QStringLiteral("id")).toString(), from,
                                                          from.addDays(7 * weeks - 1))) {
            Cells r = Report::cells({a.value(QStringLiteral("displayName")).toString(), Dates::text(c.date),
                                     Competitions::typeShortNames().value(c.type), c.name, fmt(c.bodyWeight, 1),
                                     QString::number(c.bestSnatch()), QString::number(c.bestCleanJerk())});
            r.append(Cell{QString::number(c.total()), true});
            rows.append(r);
        }
    }
    doc.note(range);
    doc.table(rows);
    return Report::toVariant(doc);
}

QVariantMap AnalysisApi::series(const QVariantMap &p) const
{
    QDate from;
    int weeks = 0;
    const QString athleteId = p.value(QStringLiteral("athleteId")).toString();
    if (athleteId.isEmpty() || !period(p, QStringLiteral("mazId"), &from, &weeks))
        return {};
    const int exercise = p.value(QStringLiteral("exercise")).toInt();
    const int volume = p.value(QStringLiteral("volume")).toInt();
    Params params;
    params.athleteId = athleteId;
    params.from = from;
    params.weeks = weeks;
    params.basis = basisFrom(p.value(QStringLiteral("basis")).toString());
    params.includeCompetitionWeeks = true;
    params.reference = referenceFrom(p.value(QStringLiteral("reference")).toString());
    params.mazId = p.value(QStringLiteral("mazId")).toString();

    auto toList = [](const QList<double> &v) {
        QVariantList l;
        for (double x : v)
            l.append(has(x) ? QVariant(qRound(x * 10) / 10.0) : QVariant());
        return l;
    };
    QVariantList labels, mhg, bw, wh;
    for (int i = 0; i < weeks; ++i)
        labels.append(Weeks::label(from.addDays(7 * i)));

    const Section s = section(params);
    for (const Row &r : s.rows) {
        if (r.key == exercise) {
            mhg = toList(r.mhg);
            bw = toList(r.bw);
            if (volume == 1)
                wh = toList(r.wh);
        }
    }
    if (volume >= 2) {
        Params g = params;
        g.groups = true;
        QList<double> sum(weeks, 0.0);
        for (const Row &r : section(g).rows) {
            const int k = -r.key;
            const bool take = volume <= 8 ? k == volume - 1 : (volume == 9 ? k <= 5 : k <= 7);
            if (!take)
                continue;
            for (int i = 0; i < weeks; ++i)
                sum[i] += has(r.wh[i]) ? r.wh[i] : 0;
        }
        wh = toList(sum);
    }
    return {{QStringLiteral("labels"), labels}, {QStringLiteral("mhg"), mhg}, {QStringLiteral("bw"), bw},
            {QStringLiteral("wh"), wh}};
}

namespace {

QPageLayout reportLayout()
{
    return QPageLayout(QPageSize(QPageSize::A4), QPageLayout::Landscape, QMarginsF(10, 10, 10, 10),
                       QPageLayout::Millimeter);
}

} // namespace

bool AnalysisApi::printReport(const QVariantMap &report) const
{
    const Report::Document doc = Report::fromVariant(report);
    QPrinter printer(QPrinter::HighResolution);
    printer.setPageLayout(reportLayout());
    printer.setDocName(doc.title);
    return PrintPreview::show(&printer, doc.title, [&doc](QPrinter *device) { Report::paint(device, doc); });
}

QString AnalysisApi::saveReport(const QVariantMap &report, const QUrl &file) const
{
    const QString path = file.toLocalFile();
    if (path.isEmpty())
        return QStringLiteral("Kein Dateiname angegeben.");
    const Report::Document doc = Report::fromVariant(report);
    if (path.endsWith(QLatin1String(".csv"), Qt::CaseInsensitive)) {
        QFile out(path);
        if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate) || out.write(Report::toCsv(doc)) < 0)
            return QStringLiteral("Die Datei kann nicht geschrieben werden: ") + out.errorString();
    } else {
        QPdfWriter writer(path);
        writer.setResolution(300);
        writer.setTitle(doc.title);
        writer.setCreator(QStringLiteral("Trainingsplaner"));
        writer.setPageLayout(reportLayout());
        Report::paint(&writer, doc);
    }
    QDesktopServices::openUrl(file);
    return QString();
}

void AnalysisApi::copyReport(const QVariantMap &report) const
{
    QGuiApplication::clipboard()->setText(Report::toText(Report::fromVariant(report)));
}
