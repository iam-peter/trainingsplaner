#include "planstore.h"

#include "bakexport.h"
#include "catalog.h"
#include "competition.h"
#include "database.h"
#include "development.h"
#include "planning.h"
#include "report.h"
#include "rtk.h"
#include "tmk.h"
#include "youth.h"

#include <QSet>

namespace {

QDate fromLabel(const QString &label)
{
    return Weeks::fromLabel(label);
}

QString label(const QDate &d)
{
    return d.isValid() ? Weeks::label(d) : QString();
}

QDate isoDate(const QString &s)
{
    return QDate::fromString(s, Qt::ISODate);
}

QVariantMap mazMap(const Maz &m)
{
    return {{QStringLiteral("id"), m.id},
            {QStringLiteral("name"), m.name},
            {QStringLiteral("shortName"), m.shortName},
            {QStringLiteral("sex"), int(m.sex)},
            {QStringLiteral("from"), label(m.from)},
            {QStringLiteral("to"), label(m.to)},
            {QStringLiteral("fromMonday"), m.from.toString(Qt::ISODate)},
            {QStringLiteral("buildUp"), label(m.buildUp)},
            {QStringLiteral("peakPhase"), label(m.peakPhase)},
            {QStringLiteral("weeks"), m.weeks()},
            {QStringLiteral("note"), m.note},
            {QStringLiteral("displayName"), m.shortName.isEmpty() ? m.name : m.shortName + QStringLiteral(" – ") + m.name}};
}

} // namespace

Plan::Plan(QObject *parent) : QObject(parent) {}

QVariantList Plan::mazList() const
{
    QVariantList list;
    for (const Maz &m : Planning::mazList())
        list.append(mazMap(m));
    return list;
}

QVariantList Plan::exerciseSets() const
{
    // The sets the old program offered, by lift and kind
    auto set = [](const QString &name, const QList<int> &ids) {
        QVariantList l;
        for (int i : ids)
            l.append(i);
        return QVariantMap{{QStringLiteral("name"), name}, {QStringLiteral("exercises"), l}};
    };
    return {set(QStringLiteral("Hauptübungen (1, 3, 5, 26, 13, 14, 19, 20)"), {1, 3, 5, 26, 13, 14, 19, 20}),
            set(QStringLiteral("Reißen-Varianten (2, 6, 7, 8, 15, 18, 22, 23)"), {2, 6, 7, 8, 15, 18, 22, 23}),
            set(QStringLiteral("Stoßen-Varianten (4, 9, 10, 11, 12, 16, 17)"), {4, 9, 10, 11, 12, 16, 17}),
            set(QStringLiteral("Kraft und Kombinationen (21, 24, 25, 27, 28, 29)"), {21, 24, 25, 27, 28, 29}),
            set(QStringLiteral("Allgemeine Kraft (30, 31, 34, 35, 36)"), {30, 31, 34, 35, 36}),
            set(QStringLiteral("Komplexe K1–K7"), {-1, -2, -3, -4, -5, -6, -7})};
}

QVariantMap Plan::maz(const QString &id) const
{
    return mazMap(Planning::maz(id));
}

QVariantMap Plan::saveMaz(const QVariantMap &v)
{
    Maz m;
    m.id = v.value(QStringLiteral("id")).toString();
    m.name = v.value(QStringLiteral("name")).toString().trimmed();
    m.shortName = v.value(QStringLiteral("shortName")).toString().trimmed();
    m.sex = sexFromInt(v.value(QStringLiteral("sex")).toInt());
    m.from = fromLabel(v.value(QStringLiteral("from")).toString());
    m.to = fromLabel(v.value(QStringLiteral("to")).toString());
    m.buildUp = fromLabel(v.value(QStringLiteral("buildUp")).toString());
    m.peakPhase = fromLabel(v.value(QStringLiteral("peakPhase")).toString());
    m.note = v.value(QStringLiteral("note")).toString();
    // What is wrong, and in which field ("name", "from", "to", "buildUp",
    // "peak"), so the form can say it there
    QString error, field;
    const bool buildUpTyped = !v.value(QStringLiteral("buildUp")).toString().trimmed().isEmpty();
    const bool peakTyped = !v.value(QStringLiteral("peakPhase")).toString().trimmed().isEmpty();
    if (m.name.isEmpty()) {
        error = QStringLiteral("Bitte eine Bezeichnung eingeben.");
        field = QStringLiteral("name");
    } else if (!m.from.isValid()) {
        error = QStringLiteral("Bitte die erste Woche angeben, z.B. 10/2027.");
        field = QStringLiteral("from");
    } else if (!m.to.isValid()) {
        error = QStringLiteral("Bitte die letzte Woche angeben, z.B. 22/2027.");
        field = QStringLiteral("to");
    } else if (m.to < m.from) {
        error = QStringLiteral("„bis“ liegt vor „von“.");
        field = QStringLiteral("to");
    } else if (m.weeks() > 104) {
        error = QStringLiteral("Ein MAZ kann höchstens 104 Wochen lang sein.");
        field = QStringLiteral("to");
    } else if (buildUpTyped && !m.buildUp.isValid()) {
        error = QStringLiteral("Die Woche der Aufbauphase ist keine Woche, z.B. 16/2027.");
        field = QStringLiteral("buildUp");
    } else if (peakTyped && !m.peakPhase.isValid()) {
        error = QStringLiteral("Die Woche der Leistungsausprägung ist keine Woche, z.B. 20/2027.");
        field = QStringLiteral("peak");
    } else if (m.buildUp.isValid() && (m.buildUp < m.from || m.buildUp > m.to)) {
        error = QStringLiteral("Die Aufbauphase muss zwischen „von“ und „bis“ beginnen.");
        field = QStringLiteral("buildUp");
    } else if (m.peakPhase.isValid() && (m.peakPhase < m.from || m.peakPhase > m.to)) {
        error = QStringLiteral("Die Leistungsausprägung muss zwischen „von“ und „bis“ beginnen.");
        field = QStringLiteral("peak");
    } else if (m.buildUp.isValid() && m.peakPhase.isValid() && m.peakPhase < m.buildUp) {
        error = QStringLiteral("Die Leistungsausprägung beginnt vor der Aufbauphase.");
        field = QStringLiteral("peak");
    }
    if (!error.isEmpty())
        return {{QStringLiteral("id"), m.id}, {QStringLiteral("error"), error}, {QStringLiteral("field"), field}};
    const bool isNew = m.id.isEmpty();
    const QString id = Planning::saveMaz(m);
    // A new MAZ from a template: its RO as the RTK's
    const QString templateKey = v.value(QStringLiteral("template")).toString();
    if (isNew && !id.isEmpty() && !templateKey.isEmpty() && !Rtk::fillRo(id, templateKey))
        error = QStringLiteral("Die Rahmenorientierung der Vorlage ließ sich nicht eintragen.");
    emit changed();
    if (id.isEmpty())
        error = QStringLiteral("Speichern fehlgeschlagen.");
    return {{QStringLiteral("id"), id}, {QStringLiteral("error"), error}};
}

QVariantList Plan::rtkTemplates() const
{
    QVariantList list;
    for (const Rtk::Template &t : Rtk::templates())
        list.append(QVariantMap{{QStringLiteral("key"), t.key}, {QStringLiteral("text"), t.title},
                                {QStringLiteral("weeks"), t.weeks}, {QStringLiteral("buildUp"), t.buildUp},
                                {QStringLiteral("peak"), t.peak}});
    return list;
}

bool Plan::removeMaz(const QString &id)
{
    const bool ok = Planning::removeMaz(id);
    emit changed();
    return ok;
}

QVariantList Plan::mazAthletes(const QString &mazId) const
{
    QVariantList list;
    for (const MazAthlete &a : Planning::mazAthletes(mazId)) {
        list.append(QVariantMap{
            {QStringLiteral("mazId"), a.mazId},
            {QStringLiteral("athleteId"), a.athleteId},
            {QStringLiteral("displayName"), Database::athlete(a.athleteId).displayName()},
            {QStringLiteral("weightClass"), a.weightClass},
            {QStringLiteral("targetSnatch"), a.targetSnatch},
            {QStringLiteral("targetCleanJerk"), a.targetCleanJerk},
            {QStringLiteral("compSnatch"), a.compSnatch},
            {QStringLiteral("compCleanJerk"), a.compCleanJerk},
            {QStringLiteral("selected"), a.selected},
            {QStringLiteral("note"), a.note},
        });
    }
    return list;
}

bool Plan::saveMazAthlete(const QVariantMap &v)
{
    MazAthlete a;
    a.mazId = v.value(QStringLiteral("mazId")).toString();
    a.athleteId = v.value(QStringLiteral("athleteId")).toString();
    a.weightClass = v.value(QStringLiteral("weightClass")).toInt();
    a.targetSnatch = v.value(QStringLiteral("targetSnatch")).toInt();
    a.targetCleanJerk = v.value(QStringLiteral("targetCleanJerk")).toInt();
    a.compSnatch = v.value(QStringLiteral("compSnatch")).toInt();
    a.compCleanJerk = v.value(QStringLiteral("compCleanJerk")).toInt();
    a.note = v.value(QStringLiteral("note")).toString();
    if (a.mazId.isEmpty() || a.athleteId.isEmpty())
        return false;
    // Without a choice in the map the stored one stays
    if (v.contains(QStringLiteral("selected"))) {
        a.selected = v.value(QStringLiteral("selected")).toBool();
    } else {
        for (const MazAthlete &old : Planning::mazAthletes(a.mazId)) {
            if (old.athleteId == a.athleteId)
                a.selected = old.selected;
        }
    }
    const bool ok = Planning::saveMazAthlete(a);
    emit changed();
    return ok;
}

bool Plan::removeMazAthlete(const QString &mazId, const QString &athleteId)
{
    const bool ok = Planning::removeMazAthlete(mazId, athleteId);
    emit changed();
    return ok;
}

QVariantList Plan::mazForAthlete(const QString &athleteId) const
{
    QVariantList list;
    for (const Maz &m : Planning::mazForAthlete(athleteId))
        list.append(mazMap(m));
    return list;
}

QString Plan::roOwner(const QString &mazId) const
{
    return Planning::roOwner(mazId);
}

bool Plan::itpFromRo(const QString &mazId, const QString &athleteId)
{
    const bool ok = Planning::itpFromRo(mazId, athleteId, Planning::weightStep());
    emit changed();
    return ok;
}

int Plan::scaleTargets(const QVariantMap &p)
{
    const QString owner = p.value(QStringLiteral("owner")).toString();
    QList<int> exercises;
    for (const QVariant &e : p.value(QStringLiteral("exercises")).toList())
        exercises.append(e.toInt());
    const int values = (p.value(QStringLiteral("wh")).toBool() ? Planning::ScaleWh : 0)
                       | (p.value(QStringLiteral("mhg")).toBool() ? Planning::ScaleMhg : 0)
                       | (p.value(QStringLiteral("bw")).toBool() ? Planning::ScaleBw : 0);
    const int percent = p.value(QStringLiteral("percent")).toInt();
    if (percent <= 0 || percent > 500)
        return -1;
    const double step = Planning::isRoOwner(owner) ? 1.0 : Planning::weightStep();
    const int n = Planning::scaleTargets(owner, isoDate(p.value(QStringLiteral("from")).toString()),
                                         isoDate(p.value(QStringLiteral("to")).toString()), exercises, values,
                                         percent / 100.0, step);
    if (n > 0)
        emit changed();
    return n;
}

bool Plan::copyPlan(const QString &fromOwner, const QString &fromMonday, const QString &toOwner,
                    const QString &toMonday, int weeks)
{
    const bool ok = Planning::copyPlan(fromOwner, isoDate(fromMonday), toOwner, isoDate(toMonday), weeks);
    emit changed();
    return ok;
}

QVariantMap Plan::loadCourse(const QString &athleteId, const QString &mazId, const QString &fromMonday,
                             int weeks, int exercise, const QString &reference) const
{
    QVariantMap result;
    if (athleteId.isEmpty() || exercise == 0)
        return result;
    QDate from = isoDate(fromMonday);
    int n = qBound(1, weeks, 104);
    MazAthlete ma;
    bool inMaz = false;
    if (!mazId.isEmpty()) {
        const Maz z = Planning::maz(mazId);
        if (z.from.isValid() && z.weeks() > 0) {
            from = z.from;
            n = qMin(z.weeks(), 104);
        }
        for (const MazAthlete &a : Planning::mazAthletes(mazId)) {
            if (a.athleteId == athleteId) {
                ma = a;
                inMaz = true;
            }
        }
    }
    if (!from.isValid())
        return result;
    const QDate to = from.addDays(7 * (n - 1));

    // What the weights are measured against
    int ref = 0;
    QString unit = QStringLiteral("kg");
    if (inMaz && (reference == QLatin1String("ziel") || reference == QLatin1String("wk"))) {
        if (reference == QLatin1String("ziel")) {
            ref = Planning::targetFor(ma, exercise);
        } else {
            const Exercise *e = Catalog::find(exercise);
            ref = e && e->lift == Exercise::Snatch ? ma.compSnatch : ma.compCleanJerk;
        }
        if (ref > 0)
            unit = QStringLiteral("%");
    }
    auto weight = [&](int kg) -> QVariant {
        if (kg <= 0)
            return QVariant();
        return ref > 0 ? QVariant(qRound(kg * 100.0 / ref)) : QVariant(kg);
    };

    // Targets: the exercise's, and K1-7 per week (a complex's own target,
    // else the sum of its exercises')
    QMap<QDate, WeekTarget> target;
    QMap<QDate, QMap<int, int>> groupWh;     // week -> group -> wh
    QMap<QDate, QSet<int>> groupOwn;
    const QList<WeekTarget> targets = Planning::targets(athleteId, from, to);
    for (const WeekTarget &t : targets) {
        if (t.exercise == exercise)
            target.insert(t.monday, t);
        if (t.exercise < 0 && -t.exercise <= Catalog::summaryGroups && t.wh > 0) {
            groupWh[t.monday][-t.exercise] = t.wh;
            groupOwn[t.monday].insert(-t.exercise);
        }
    }
    for (const WeekTarget &t : targets) {
        const Exercise *e = t.exercise > 0 ? Catalog::find(t.exercise) : nullptr;
        if (e && e->group >= 1 && e->group <= Catalog::summaryGroups && !groupOwn[t.monday].contains(e->group))
            groupWh[t.monday][e->group] += t.wh;
    }
    QMap<QDate, int> load;
    QMap<QDate, QString> position;
    for (const WeekMeta &m : Planning::meta(athleteId, from, to)) {
        load.insert(m.monday, m.load);
        position.insert(m.monday, m.position);
    }
    // Tr.-Wo.: in a MAZ, the weeks to its main competition
    const Maz cycle = inMaz ? Planning::maz(mazId) : Maz();
    const QDate mainWeek = Planning::mainCompetitionWeek(cycle, athleteId);

    // Done and planned: the exercise, and the reps of K1-7
    struct Done { QMap<QDate, QList<Step>> exercise; QMap<QDate, int> wh17; };
    auto collect = [&](Variant v) {
        Done d;
        for (const Database::WeightLine &l : Database::weightLines(athleteId, v, from, to)) {
            if (l.exercise == exercise)
                d.exercise[l.monday] += l.steps;
            const Exercise *e = Catalog::find(l.exercise);
            if (e && e->group >= 1 && e->group <= Catalog::summaryGroups)
                d.wh17[l.monday] += Steps::compute(l.steps).wh;
        }
        return d;
    };
    const Done actual = collect(Variant::Actual);
    const Done planned = collect(Variant::Plan);

    const QDate todayMonday = Weeks::mondayOf(QDate::currentDate());
    int todayIndex = -1;
    QVariantList labels, mondays, loads, norms, positions, countdowns;
    QVariantList zMhg, zBw, zWh, iMhg, iBw, iWh, pMhg, pBw, pWh;
    // The TMK's K1-7 a week for the athlete's age in each week
    const QDate born = Database::athlete(athleteId).born;
    QStringList normTexts;
    auto opt = [](int v) { return v > 0 ? QVariant(v) : QVariant(); };
    Report::Document doc;
    const QString exName = Catalog::name(exercise);
    doc.title = QStringLiteral("Belastungsverlauf TÜ %1 %2").arg(exercise).arg(exName);
    QList<Report::Cells> rows;
    rows.append(Report::cells({QStringLiteral("KW"), QStringLiteral("Tr.-Wo."), QStringLiteral("WK"), QStringLiteral("Bel."),
                               QStringLiteral("BW Ziel"), QStringLiteral("BW Ist"), QStringLiteral("BW Plan"),
                               QStringLiteral("MHG Ziel"), QStringLiteral("MHG Ist"), QStringLiteral("MHG Plan"),
                               QStringLiteral("WH K1-7 Ziel"), QStringLiteral("WH K1-7 Ist"), QStringLiteral("WH K1-7 Plan")}));
    auto text = [](const QVariant &v) { return v.isValid() ? v.toString() : QString(); };
    for (int i = 0; i < n; ++i) {
        const QDate m = from.addDays(7 * i);
        if (m == todayMonday)
            todayIndex = i;
        labels.append(QString::number(m.weekNumber()));
        mondays.append(m.toString(Qt::ISODate));
        loads.append(Planning::loadText(load.value(m)));
        positions.append(position.value(m));
        const int countdown = Planning::trainingWeek(cycle, mainWeek, m);
        countdowns.append(countdown > 0 ? QVariant(countdown) : QVariant());
        if (born.isValid()) {
            const Tmk::Stage stage = Tmk::stage(Youth::ageClass(born, m));
            norms.append(Tmk::weeklyWh(0, stage));
            const QString text = QStringLiteral("%1: %2 WH").arg(Tmk::stageName(stage)).arg(Tmk::weeklyWh(0, stage));
            if (!normTexts.contains(text))
                normTexts.append(text);
        } else {
            norms.append(QVariant());
        }
        const WeekTarget t = target.value(m);
        int z17 = 0;
        for (int w : groupWh.value(m))
            z17 += w;
        const Stats a = Steps::compute(actual.exercise.value(m));
        const Stats p = Steps::compute(planned.exercise.value(m));
        zMhg.append(weight(t.mhg));
        zBw.append(weight(t.bw));
        zWh.append(opt(z17));
        iMhg.append(weight(a.mhg));
        iBw.append(weight(a.bw));
        iWh.append(opt(actual.wh17.value(m)));
        pMhg.append(weight(p.mhg));
        pBw.append(weight(p.bw));
        pWh.append(opt(planned.wh17.value(m)));
        rows.append(Report::cells({QString::number(m.weekNumber()), text(countdowns.last()), position.value(m),
                                   Planning::loadText(load.value(m)),
                                   text(zBw.last()), text(iBw.last()), text(pBw.last()),
                                   text(zMhg.last()), text(iMhg.last()), text(pMhg.last()),
                                   text(zWh.last()), text(iWh.last()), text(pWh.last())}));
    }
    doc.note(QStringLiteral("Gewichte in %1").arg(ref > 0 ? (reference == QLatin1String("ziel")
                                                               ? QStringLiteral("% des MAZ-Ziels (%1 kg)").arg(ref)
                                                               : QStringLiteral("% des MAZ-Wettkampfs (%1 kg)").arg(ref))
                                                         : QStringLiteral("kg")));
    const QString normText = normTexts.isEmpty()
                                 ? QString()
                                 : QStringLiteral("Richtwert K1-7 nach TMK 2018 im Mittel je Woche, %1")
                                       .arg(normTexts.join(QStringLiteral(", ")));
    if (!normText.isEmpty())
        doc.note(normText);
    doc.table(rows);
    result = {{QStringLiteral("labels"), labels},
              {QStringLiteral("norm"), norms}, {QStringLiteral("normText"), normText},
              {QStringLiteral("position"), positions}, {QStringLiteral("countdown"), countdowns}, {QStringLiteral("mondays"), mondays}, {QStringLiteral("load"), loads},
              {QStringLiteral("todayIndex"), todayIndex}, {QStringLiteral("unit"), unit},
              {QStringLiteral("reference"), ref},
              {QStringLiteral("target"), QVariantMap{{QStringLiteral("mhg"), zMhg}, {QStringLiteral("bw"), zBw}, {QStringLiteral("wh"), zWh}}},
              {QStringLiteral("actual"), QVariantMap{{QStringLiteral("mhg"), iMhg}, {QStringLiteral("bw"), iBw}, {QStringLiteral("wh"), iWh}}},
              {QStringLiteral("planned"), QVariantMap{{QStringLiteral("mhg"), pMhg}, {QStringLiteral("bw"), pBw}, {QStringLiteral("wh"), pWh}}},
              {QStringLiteral("report"), Report::toVariant(doc)}};
    return result;
}

QVariantMap Plan::intensityBand(int exercise) const
{
    const Rtk::IntensityBand b = Rtk::intensityBand(exercise);
    if (b.name.isEmpty())
        return {{QStringLiteral("has"), false}};
    return {{QStringLiteral("has"), true}, {QStringLiteral("name"), b.name},
            {QStringLiteral("low"), b.low}, {QStringLiteral("high"), b.high},
            {QStringLiteral("text"), QStringLiteral("%1: %2–%3 % des Wettkampfziels (RTK, Aufbautraining)")
                                         .arg(b.name).arg(b.low).arg(b.high)}};
}

QVariantMap Plan::targetCheck(const QString &mazId, const QString &athleteId, int targetSnatch,
                              int targetCleanJerk) const
{
    QVariantMap result{{QStringLiteral("has"), false}};
    const Maz m = Planning::maz(mazId);
    if (!m.from.isValid() || athleteId.isEmpty())
        return result;
    // The yearly bests before the MAZ: what the planning could know
    QList<Competition> before;
    for (const Competition &c : Competitions::forAthlete(athleteId)) {
        if (c.date < m.from)
            before.append(c);
    }
    const QList<Competitions::Point> points = Competitions::bestResults(before, 2);
    QList<double> t, y;
    const Competitions::Point *latest = nullptr;
    for (const Competitions::Point &p : points) {
        if (p.total > 0) {
            t.append(p.date.year());
            y.append(p.total);
            if (p.snatch > 0 && p.cleanJerk > 0)
                latest = &p;
        }
    }
    const Development::Fit f = Development::gompertz(t, y);
    if (!f.ok)
        return result;
    const int year = Planning::mainCompetitionWeek(m, athleteId).addDays(5).year();
    const double expected = Development::value(f, year);
    const double tolerance = qMax(qMax(2 * f.se, 0.03 * expected), 3.0);
    const int total = qRound(expected);
    // Split as the athlete's latest yearly best was
    const double share = latest ? double(latest->snatch) / latest->total : 0.44;
    const int snatch = qRound(total * share);
    result = {{QStringLiteral("has"), true},
              {QStringLiteral("expected"), qRound(expected * 10) / 10.0},
              {QStringLiteral("tolerance"), qRound(tolerance * 10) / 10.0},
              {QStringLiteral("year"), year},
              {QStringLiteral("proposedSnatch"), snatch},
              {QStringLiteral("proposedCleanJerk"), total - snatch}};
    const QString curve = QStringLiteral("Entwicklungskurve (%1 kg für %2)").arg(total).arg(year);
    if (targetSnatch <= 0 || targetCleanJerk <= 0) {
        result.insert(QStringLiteral("verdict"), QString());
        result.insert(QStringLiteral("text"), QStringLiteral("Nach der %1: Vorschlag %2 / %3 kg.")
                                                  .arg(curve).arg(snatch).arg(total - snatch));
        return result;
    }
    const int target = targetSnatch + targetCleanJerk;
    const double diff = target - expected;
    QString verdict, text;
    if (diff > tolerance) {
        verdict = QStringLiteral("high");
        text = QStringLiteral("Zweikampf-Ziel %1 kg liegt %2 kg über der %3.").arg(target).arg(qRound(diff)).arg(curve);
    } else if (diff < -tolerance) {
        verdict = QStringLiteral("low");
        text = QStringLiteral("Zweikampf-Ziel %1 kg liegt %2 kg unter der %3.").arg(target).arg(qRound(-diff)).arg(curve);
    } else {
        verdict = QStringLiteral("ok");
        text = QStringLiteral("Zweikampf-Ziel %1 kg passt zur %2.").arg(target).arg(curve);
    }
    result.insert(QStringLiteral("verdict"), verdict);
    result.insert(QStringLiteral("text"), text);
    return result;
}

QVariantList Plan::plannedSteps(const QString &owner, int exercise, const QString &fromMonday, int weeks) const
{
    const QDate from = isoDate(fromMonday);
    const int n = qBound(0, weeks, 260);
    const QMap<QDate, QList<Step>> steps =
        Planning::plannedSteps(owner, exercise, from, from.addDays(7 * qMax(0, n - 1)));
    QVariantList list;
    for (int i = 0; i < n; ++i) {
        const QDate m = from.addDays(7 * i);
        const QList<Step> s = steps.value(m);
        const Stats st = Steps::compute(s);
        list.append(QVariantMap{{QStringLiteral("monday"), m.toString(Qt::ISODate)},
                                {QStringLiteral("label"), Weeks::label(m)},
                                {QStringLiteral("text"), Planning::stepsText(s)},
                                {QStringLiteral("wh"), st.wh},
                                {QStringLiteral("mhg"), st.mhg},
                                {QStringLiteral("bw"), st.bw}});
    }
    return list;
}

QString Plan::setPlannedSteps(const QString &owner, int exercise, const QString &monday, const QString &text)
{
    bool ok = false;
    const QList<Step> steps = Planning::parseStepsText(text, &ok);
    if (!ok)
        return QStringLiteral("Bitte Laststufen als kg/Wdh/Sätze eingeben, z.B. 80/3/2 85/3/2");
    if (!Planning::setPlannedSteps(owner, exercise, isoDate(monday), steps))
        return QStringLiteral("Speichern fehlgeschlagen.");
    emit changed();
    return QString();
}

bool Plan::setWeekLoad(const QString &athleteId, const QString &monday, const QString &load)
{
    const QDate m = isoDate(monday);
    const int value = Planning::loadFromText(load);
    if (athleteId.isEmpty() || !m.isValid() || value < 0)
        return false;
    WeekMeta meta;
    meta.monday = m;
    for (const WeekMeta &w : Planning::meta(athleteId, m, m))
        meta = w;
    if (meta.load == value)
        return true;
    meta.load = value;
    if (!Planning::setMeta(athleteId, meta))
        return false;
    emit changed();
    return true;
}

QVariantMap Plan::itpForWeek(const QString &athleteId, const QString &monday, int exercise) const
{
    const QDate m = isoDate(monday);
    WeekTarget t;
    for (const WeekTarget &x : Planning::targets(athleteId, m, m)) {
        if (x.exercise == exercise)
            t = x;
    }
    const QList<Step> steps = Planning::plannedSteps(athleteId, exercise, m, m).value(m);
    return {{QStringLiteral("has"), !t.isEmpty() || !steps.isEmpty()},
            {QStringLiteral("wh"), t.wh},
            {QStringLiteral("mhg"), t.mhg},
            {QStringLiteral("bw"), t.bw},
            {QStringLiteral("repsSets"), t.bwReps > 0 ? QStringLiteral("%1/%2").arg(t.bwReps).arg(t.bwSets) : QString()},
            {QStringLiteral("steps"), Planning::stepsText(steps)}};
}

QString Plan::exportMaz(const QUrl &file, const QString &mazId)
{
    BakExport::Filter f;
    f.mode = BakExport::Filter::Maz;
    f.mazId = mazId;
    return BakExport::exportFile(file.toLocalFile(), f).summary();
}

QString Plan::weekLabel(const QString &monday) const
{
    return label(isoDate(monday));
}

QString Plan::mondayFromLabel(const QString &l) const
{
    const QDate d = fromLabel(l);
    return d.isValid() ? d.toString(Qt::ISODate) : QString();
}
