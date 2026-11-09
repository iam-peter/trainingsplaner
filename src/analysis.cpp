#include "analysis.h"

#include "catalog.h"
#include "competition.h"
#include "database.h"

#include <QMap>
#include <QSqlQuery>

#include <algorithm>

namespace {

using namespace Analysis;

// What one row collects in one week
struct WeekBucket
{
    QList<Step> steps;
    WeekTarget target; // ITP basis
    bool hasTarget = false;
};

int keyFor(int exercise, bool groups)
{
    if (!groups)
        return exercise;
    const Exercise *e = Catalog::find(exercise);
    return e && e->group >= 1 && e->group <= Catalog::summaryGroups ? -e->group : 0;
}

QString nameFor(int key)
{
    if (key < 0)
        return QStringLiteral("K%1").arg(-key);
    return QStringLiteral("%1 %2").arg(key).arg(Catalog::name(key));
}

double maxOf(const QList<double> &v)
{
    double m = none;
    for (double x : v) {
        if (has(x) && (!has(m) || x > m))
            m = x;
    }
    return m;
}

} // namespace

namespace Analysis {

double slope(const QList<double> &values)
{
    double n = 0, sx = 0, sy = 0, sxx = 0, sxy = 0;
    for (int i = 0; i < values.size(); ++i) {
        if (!has(values[i]))
            continue;
        n += 1;
        sx += i;
        sy += values[i];
        sxx += double(i) * i;
        sxy += i * values[i];
    }
    const double d = n * sxx - sx * sx;
    if (n < 2 || d == 0)
        return none;
    return (n * sxy - sx * sy) / d;
}

Section section(const Params &p)
{
    Section s;
    for (int i = 0; i < p.weeks; ++i) {
        const QDate m = p.from.addDays(7 * i);
        s.weeks.append(m);
        const bool comp = !p.includeCompetitionWeeks && Competitions::inWeek(p.athleteId, m);
        s.excluded.append(comp);
        if (!comp)
            ++s.countedWeeks;
    }
    if (p.weeks <= 0)
        return s;
    const QDate to = p.from.addDays(7 * (p.weeks - 1));

    // Collect per row and week
    QMap<int, QMap<int, WeekBucket>> buckets; // key -> week index -> bucket
    if (p.basis == Basis::Itp) {
        for (const WeekTarget &t : Planning::targets(p.athleteId, p.from, to)) {
            const int key = p.groups ? (t.exercise < 0 ? t.exercise : 0) : (t.exercise > 0 ? t.exercise : 0);
            if (key == 0)
                continue;
            WeekBucket &b = buckets[key][int(p.from.daysTo(t.monday) / 7)];
            b.target = t;
            b.hasTarget = true;
        }
    } else {
        const Variant v = p.basis == Basis::Plan ? Variant::Plan : Variant::Actual;
        for (const Database::WeightLine &l : Database::weightLines(p.athleteId, v, p.from, to)) {
            const int key = keyFor(l.exercise, p.groups);
            if (key != 0)
                buckets[key][int(p.from.daysTo(l.monday) / 7)].steps += l.steps;
        }
        for (int i = 0; i < p.weeks; ++i) {
            if (s.excluded[i])
                continue;
            const Week w = Database::loadWeek(p.athleteId, s.weeks[i], v);
            for (const Session &ses : w.sessions) {
                if (!ses.entries.isEmpty())
                    s.sessions += 1;
            }
        }
    }

    // Reference values for percent
    MazAthlete ref;
    bool hasRef = false;
    if (p.reference != Reference::Absolute && !p.mazId.isEmpty()) {
        for (const MazAthlete &a : Planning::mazAthletes(p.mazId)) {
            if (a.athleteId == p.athleteId) {
                ref = a;
                hasRef = true;
            }
        }
        if (p.reference == Reference::MazCompetition) {
            ref.targetSnatch = ref.compSnatch;
            ref.targetCleanJerk = ref.compCleanJerk;
        }
    }

    for (auto it = buckets.cbegin(); it != buckets.cend(); ++it) {
        Row r;
        r.key = it.key();
        r.name = nameFor(r.key);
        const double refKg = hasRef ? Planning::targetFor(ref, r.key) : 0;
        r.percent = refKg > 0;
        auto scale = [&](double kg) { return has(kg) && r.percent ? kg * 100.0 / refKg : kg; };

        QList<Step> allSteps;
        double whSum = 0, tonnage = 0, sets = 0;
        QList<QPair<int, int>> attempts; // (kg, set size), one per repetition
        for (int i = 0; i < p.weeks; ++i) {
            const WeekBucket b = it.value().value(i);
            if (s.excluded[i]) {
                r.wh.append(none); r.mhg.append(none); r.bw.append(none); r.sg.append(none);
                continue;
            }
            if (p.basis == Basis::Itp) {
                const WeekTarget &t = b.target;
                r.wh.append(b.hasTarget && t.wh > 0 ? double(t.wh) : none);
                r.mhg.append(b.hasTarget && t.mhg > 0 ? scale(t.mhg) : none);
                r.bw.append(b.hasTarget && t.bw > 0 ? scale(t.bw) : none);
                r.sg.append(none);
                if (b.hasTarget && t.wh > 0) {
                    whSum += t.wh;
                    tonnage += double(t.wh) * t.mhg;
                }
                continue;
            }
            const Stats st = Steps::compute(b.steps);
            if (st.wh == 0) {
                r.wh.append(none); r.mhg.append(none); r.bw.append(none); r.sg.append(none);
                continue;
            }
            int weekSets = 0;
            for (const Step &x : b.steps) {
                weekSets += x.sets;
                for (int k = 0; k < x.reps * x.sets; ++k)
                    attempts.append({x.kg, x.reps});
            }
            allSteps += b.steps;
            whSum += st.wh;
            tonnage += st.tonnage;
            sets += weekSets;
            r.wh.append(st.wh);
            r.mhg.append(scale(st.tonnage / st.wh));
            r.bw.append(scale(st.bw));
            r.sg.append(weekSets > 0 ? double(st.wh) / weekSets : none);
        }
        if (whSum <= 0)
            continue;

        r.whTotal = whSum;
        r.whPerWeek = s.countedWeeks > 0 ? whSum / s.countedWeeks : none;
        r.whTrend = slope(r.wh);
        r.mhgMax = maxOf(r.mhg);
        r.mhgPeriod = tonnage > 0 ? scale(tonnage / whSum) : none;
        r.mhgTrend = slope(r.mhg);
        r.bwMax = maxOf(r.bw);
        r.bwTrend = slope(r.bw);
        if (p.basis != Basis::Itp) {
            std::sort(attempts.begin(), attempts.end(), [](const auto &a, const auto &b) { return a.first > b.first; });
            const int n = qMin(30, int(attempts.size()));
            double kgSum = 0, sgSum = 0;
            for (int i = 0; i < n; ++i) {
                kgSum += attempts[i].first;
                sgSum += attempts[i].second;
            }
            r.mhgTop30 = n > 0 ? scale(kgSum / n) : none;
            r.sgTop30 = n > 0 ? sgSum / n : none;
            r.sgMean = sets > 0 ? whSum / sets : none;
            int failed = 0;
            for (const Step &x : allSteps)
                failed += x.failed;
            r.failed = failed;
        }
        s.rows.append(r);
    }
    // Groups in order K1..K7, exercises by number
    std::sort(s.rows.begin(), s.rows.end(), [](const Row &a, const Row &b) {
        if ((a.key < 0) != (b.key < 0))
            return a.key < 0;
        return a.key < 0 ? a.key > b.key : a.key < b.key;
    });
    return s;
}

LoadTable loadTable(const QString &athleteId, Variant variant, int exercise, const QDate &from, int weeks)
{
    LoadTable t;
    QMap<int, QList<int>> byKg;
    for (int i = 0; i < weeks; ++i)
        t.weeks.append(from.addDays(7 * i));
    if (weeks <= 0)
        return t;
    for (const Database::ExerciseUse &u : Database::exerciseUses(athleteId, variant, exercise, from,
                                                                  from.addDays(7 * (weeks - 1)))) {
        const int w = int(from.daysTo(u.monday) / 7);
        for (const Step &s : u.steps) {
            QList<int> &row = byKg[s.kg];
            if (row.isEmpty())
                row = QList<int>(weeks, 0);
            row[w] += s.reps * s.sets;
        }
    }
    for (auto it = byKg.cend(); it != byKg.cbegin();) {
        --it;
        t.kg.append(it.key());
        t.reps.append(it.value());
        int sum = 0;
        for (int v : it.value())
            sum += v;
        t.totals.append(sum);
    }
    return t;
}

QList<int> sessionCounts(const QString &athleteId, const QDate &from, int weeks, Variant variant)
{
    QList<int> counts(qMax(0, weeks), 0);
    if (weeks <= 0)
        return counts;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT monday, COUNT(DISTINCT day || '-' || number) FROM session_entries"
                             " WHERE athlete_id = ? AND variant = ? AND monday BETWEEN ? AND ? GROUP BY monday"));
    q.addBindValue(athleteId);
    q.addBindValue(QString(variantCode(variant)));
    q.addBindValue(from.toString(Qt::ISODate));
    q.addBindValue(from.addDays(7 * (weeks - 1)).toString(Qt::ISODate));
    if (!q.exec())
        return counts;
    while (q.next()) {
        const int w = int(from.daysTo(QDate::fromString(q.value(0).toString(), Qt::ISODate)) / 7);
        if (w >= 0 && w < weeks)
            counts[w] = q.value(1).toInt();
    }
    return counts;
}

} // namespace Analysis
