#include "planstore.h"

#include "bakexport.h"
#include "database.h"
#include "planning.h"

#include <QSettings>

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

double weightStep()
{
    return QSettings().value(QStringLiteral("general/weightStep"), 2.5).toDouble() == 1.0 ? 1.0 : 2.5;
}

QVariantMap mazMap(const Maz &m)
{
    return {{QStringLiteral("id"), m.id},
            {QStringLiteral("name"), m.name},
            {QStringLiteral("shortName"), m.shortName},
            {QStringLiteral("sex"), m.sex},
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
    m.sex = v.value(QStringLiteral("sex")).toInt();
    m.from = fromLabel(v.value(QStringLiteral("from")).toString());
    m.to = fromLabel(v.value(QStringLiteral("to")).toString());
    m.buildUp = fromLabel(v.value(QStringLiteral("buildUp")).toString());
    m.peakPhase = fromLabel(v.value(QStringLiteral("peakPhase")).toString());
    m.note = v.value(QStringLiteral("note")).toString();
    QString error;
    if (m.name.isEmpty())
        error = QStringLiteral("Bitte eine Bezeichnung eingeben.");
    else if (!m.from.isValid() || !m.to.isValid())
        error = QStringLiteral("Bitte Wochen „von“ und „bis“ angeben, z.B. 10/2027.");
    else if (m.to < m.from)
        error = QStringLiteral("„bis“ liegt vor „von“.");
    else if (m.weeks() > 104)
        error = QStringLiteral("Ein MAZ kann höchstens 104 Wochen lang sein.");
    if (!error.isEmpty())
        return {{QStringLiteral("id"), m.id}, {QStringLiteral("error"), error}};
    const QString id = Planning::saveMaz(m);
    emit changed();
    return {{QStringLiteral("id"), id},
            {QStringLiteral("error"), id.isEmpty() ? QStringLiteral("Speichern fehlgeschlagen.") : QString()}};
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
    const bool ok = Planning::itpFromRo(mazId, athleteId, weightStep());
    emit changed();
    return ok;
}

bool Plan::copyPlan(const QString &fromOwner, const QString &fromMonday, const QString &toOwner,
                    const QString &toMonday, int weeks)
{
    const bool ok = Planning::copyPlan(fromOwner, isoDate(fromMonday), toOwner, isoDate(toMonday), weeks);
    emit changed();
    return ok;
}

QVariantMap Plan::comparison(const QString &athleteId, const QString &fromMonday, int weeks, int exercise,
                             const QString &basis) const
{
    const QDate from = isoDate(fromMonday);
    const int n = qBound(1, weeks, 260);
    const QDate to = from.addDays(7 * (n - 1));
    QMap<QDate, WeekTarget> itp;
    for (const WeekTarget &t : Planning::targets(athleteId, from, to)) {
        if (t.exercise == exercise)
            itp.insert(t.monday, t);
    }
    const QMap<QDate, Stats> act = Planning::actualWeekly(
        athleteId, basis == QLatin1String("I") ? Variant::Actual : Variant::Plan, exercise, from, to);
    QVariantList labels, iWh, iMhg, iBw, aWh, aMhg, aBw;
    auto opt = [](int v) { return v > 0 ? QVariant(v) : QVariant(); };
    for (int i = 0; i < n; ++i) {
        const QDate m = from.addDays(7 * i);
        labels.append(Weeks::label(m));
        const WeekTarget t = itp.value(m);
        iWh.append(t.wh);
        iMhg.append(opt(t.mhg));
        iBw.append(opt(t.bw));
        const Stats s = act.value(m);
        aWh.append(s.wh);
        aMhg.append(opt(s.mhg));
        aBw.append(opt(s.bw));
    }
    return {{QStringLiteral("labels"), labels}, {QStringLiteral("itpWh"), iWh}, {QStringLiteral("itpMhg"), iMhg},
            {QStringLiteral("itpBw"), iBw}, {QStringLiteral("actWh"), aWh}, {QStringLiteral("actMhg"), aMhg},
            {QStringLiteral("actBw"), aBw}};
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
