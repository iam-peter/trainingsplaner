#include "itpmodel.h"

#include "catalog.h"
#include "database.h"
#include "tmk.h"
#include "youth.h"

ItpModel::ItpModel(QObject *parent) : QAbstractTableModel(parent)
{
    layColumns();
}

void ItpModel::layColumns()
{
    m_columns.clear();
    for (int e : std::as_const(m_exercises)) {
        m_columns.append({Wh, e});
        if (e > 0) {
            m_columns.append({Mhg, e});
            m_columns.append({Bw, e});
        }
    }
    m_columns.append({Sum17, 0});
    m_columns.append({Sum15, 0});
    m_columns.append({Load, 0});
    m_columns.append({Position, 0});
}

void ItpModel::setOwner(const QString &v)
{
    if (v == m_owner)
        return;
    m_owner = v;
    reload();
}

void ItpModel::setFromMonday(const QString &v)
{
    const QDate d = QDate::fromString(v, Qt::ISODate);
    if (d == m_from)
        return;
    m_from = d;
    reload();
}

void ItpModel::setWeeks(int v)
{
    v = qBound(0, v, 260);
    if (v == m_weeks)
        return;
    beginResetModel();
    m_weeks = v;
    load();
    endResetModel();
    emit configChanged();
}

QVariantList ItpModel::exercises() const
{
    QVariantList list;
    for (int e : m_exercises)
        list.append(e);
    return list;
}

void ItpModel::setExercises(const QVariantList &v)
{
    QList<int> list;
    for (const QVariant &e : v)
        list.append(e.toInt());
    if (list == m_exercises)
        return;
    beginResetModel();
    m_exercises = list;
    layColumns();
    load();
    endResetModel();
    emit configChanged();
}

void ItpModel::setMazId(const QString &v)
{
    if (v == m_mazId)
        return;
    m_mazId = v;
    reload();
}

void ItpModel::setAverageAllWeeks(bool v)
{
    if (v == m_averageAll)
        return;
    m_averageAll = v;
    reload();
}

// New numbers in the same grid (only the weeks and the exercises change
// its shape): the cells stay and read them anew instead of being built
// again
void ItpModel::reload()
{
    load();
    if (rowCount() > 0 && columnCount() > 0)
        emit dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1));
    emit configChanged();
}

void ItpModel::load()
{
    m_targets.clear();
    m_meta.clear();
    m_maz = m_mazId.isEmpty() ? Maz() : Planning::maz(m_mazId);
    if (!m_owner.isEmpty() && m_from.isValid() && m_weeks > 0) {
        const QDate to = m_from.addDays(7 * (m_weeks - 1));
        for (const WeekTarget &t : Planning::targets(m_owner, m_from, to))
            m_targets.insert({t.monday, t.exercise}, t);
        for (const WeekMeta &m : Planning::meta(m_owner, m_from, to))
            m_meta.insert(m.monday, m);
    }
    m_born = QDate();
    m_athlete = MazAthlete();
    if (percent()) {
        // A RO is for all athletes of its MAZ: the youngest set the caps
        for (const MazAthlete &a : Planning::mazAthletes(m_owner.mid(1))) {
            const QDate born = Database::athlete(a.athleteId).born;
            if (born.isValid() && (!m_born.isValid() || born.year() > m_born.year()))
                m_born = born;
        }
    } else if (!m_owner.isEmpty()) {
        m_born = Database::athlete(m_owner).born;
        if (!m_mazId.isEmpty()) {
            for (const MazAthlete &a : Planning::mazAthletes(m_mazId)) {
                if (a.athleteId == m_owner)
                    m_athlete = a;
            }
        }
    }
}

int ItpModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() || m_weeks == 0 ? 0 : m_weeks + 1;
}

int ItpModel::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_columns.size());
}

ItpModel::Kind ItpModel::kindOf(int column) const
{
    return column >= 0 && column < m_columns.size() ? m_columns.at(column).kind : Position;
}

int ItpModel::exerciseOf(int column) const
{
    return column >= 0 && column < m_columns.size() ? m_columns.at(column).exercise : 0;
}

// WH of the complexes K1 up to K<last> in a week
int ItpModel::complexSum(const QDate &monday, int last) const
{
    int sum = 0;
    for (int k = 1; k <= last; ++k)
        sum += m_targets.value({monday, -k}).wh;
    return sum;
}

QString ItpModel::warning(int row, int column) const
{
    const Kind k = kindOf(column);
    const int e = exerciseOf(column);
    if (row >= m_weeks || !m_born.isValid() || e == 0 || (k != Wh && k != Mhg && k != Bw)
        || value(row, column) <= 0)
        return {};
    const QDate monday = m_from.addDays(7 * row);
    const Tmk::Stage stage = Tmk::stage(Youth::ageClass(m_born, monday));
    const QString who = percent() ? QStringLiteral(" Die Jüngsten der MAZ sind %1.").arg(Tmk::stageName(stage))
                                  : QString();
    const QString notForStage = Tmk::notForStage(e, stage);
    if (!notForStage.isEmpty())
        return notForStage + who;
    const Tmk::Entry tmk = Tmk::entry(e, stage);
    if (k != Bw || tmk.bw == 0 || Tmk::exemptInCompetition(e, m_meta.value(monday).position))
        return {};
    QString text = QStringLiteral("Über dem TMK 2018 für %1: BW bis %2 % des Wettkampfziels")
                       .arg(Tmk::stageName(stage))
                       .arg(tmk.bw);
    if (tmk.text.contains(QLatin1Char('/')))
        text += QStringLiteral(" (%1: BW/SG)").arg(tmk.text);
    if (percent())
        return value(row, column) > tmk.bw ? text + QLatin1Char('.') + who : QString();
    // An ITP in kg: the cap as the ITP of a RO would round it
    const int target = Planning::targetFor(m_athlete, e);
    if (target <= 0)
        return {};
    const int cap = Planning::roundToStep(tmk.bw * target / 100.0, Planning::weightStep());
    if (value(row, column) <= cap)
        return {};
    return text + QStringLiteral(", %1 kg bei %2 kg Ziel.").arg(cap).arg(target);
}

int ItpModel::value(int row, int column) const
{
    const QDate monday = m_from.addDays(7 * row);
    const Kind k = kindOf(column);
    if (k == Load)
        return m_meta.value(monday).load;
    if (k == Sum17 || k == Sum15)
        return complexSum(monday, k == Sum17 ? 7 : 5);
    const WeekTarget t = m_targets.value({monday, exerciseOf(column)});
    return k == Wh ? t.wh : k == Mhg ? t.mhg : t.bw;
}

QVariant ItpModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};
    const int row = index.row(), col = index.column();
    const bool average = row == m_weeks;
    const Kind k = kindOf(col);
    switch (role) {
    case AverageRole:
        return average;
    case KindRole:
        return int(k);
    case ExerciseRole:
        return exerciseOf(col);
    case WarningRole:
        return average ? QString() : warning(row, col);
    case Qt::DisplayRole:
    case EditRole: {
        if (average) {
            if (k == Position || k == Load)
                return QString();
            // Averages: of the weeks with a value, or of all weeks
            double sum = 0;
            int n = 0;
            for (int r = 0; r < m_weeks; ++r) {
                const int v = value(r, col);
                if (v > 0) {
                    sum += v;
                    ++n;
                }
            }
            const int divisor = m_averageAll ? m_weeks : n;
            return divisor > 0 && sum > 0 ? QString::number(qRound(sum / divisor)) : QString();
        }
        if (k == Position)
            return m_meta.value(m_from.addDays(7 * row)).position;
        if (k == Load)
            return Planning::loadText(value(row, col));
        const int v = value(row, col);
        return v > 0 ? QString::number(v) : QString();
    }
    }
    return {};
}

bool ItpModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || role != EditRole || index.row() >= m_weeks || m_owner.isEmpty())
        return false;
    const QDate monday = m_from.addDays(7 * index.row());
    const Kind k = kindOf(index.column());
    // The sums follow their complexes
    if (k == Sum17 || k == Sum15)
        return false;
    const QString text = value.toString().trimmed();
    bool ok = true;
    if (k == Load || k == Position) {
        WeekMeta m = m_meta.value(monday);
        m.monday = monday;
        if (k == Load) {
            m.load = Planning::loadFromText(text);
            if (m.load < 0)
                return false;
        } else
            m.position = text.left(5);
        ok = Planning::setMeta(m_owner, m);
        if (ok)
            m_meta.insert(monday, m);
    } else {
        const int exercise = exerciseOf(index.column());
        WeekTarget t = m_targets.value({monday, exercise});
        t.monday = monday;
        t.exercise = exercise;
        const int v = qBound(0, text.toInt(), 9999);
        (k == Wh ? t.wh : k == Mhg ? t.mhg : t.bw) = v;
        ok = Planning::setTarget(m_owner, t);
        if (ok)
            m_targets.insert({monday, exercise}, t);
    }
    if (ok) {
        emit dataChanged(index, index);
        // A competition in the week lifts the cap of Reißen and Stoßen
        if (k == Position)
            emit dataChanged(this->index(index.row(), 0), this->index(index.row(), columnCount() - 1));
        const QModelIndex avg = this->index(m_weeks, index.column());
        emit dataChanged(avg, avg);
        // A complex's WH: the week's sums and their averages too
        if (exerciseOf(index.column()) < 0) {
            for (int c = 0; c < m_columns.size(); ++c) {
                if (m_columns[c].kind == Sum17 || m_columns[c].kind == Sum15) {
                    emit dataChanged(this->index(index.row(), c), this->index(index.row(), c));
                    emit dataChanged(this->index(m_weeks, c), this->index(m_weeks, c));
                }
            }
        }
    }
    return ok;
}

QVariantMap ItpModel::columnInfo(int column) const
{
    const Kind k = kindOf(column);
    if (k == Sum17 || k == Sum15)
        return {{QStringLiteral("title"), k == Sum17 ? QStringLiteral("K1-7") : QStringLiteral("K1-5")},
                {QStringLiteral("sub"), QStringLiteral("WH")}, {QStringLiteral("first"), true},
                {QStringLiteral("exercise"), 0}, {QStringLiteral("readOnly"), true},
                {QStringLiteral("tip"), k == Sum17 ? QStringLiteral("Summe der Komplexe K1 bis K7, aus deren WH")
                                                   : QStringLiteral("Summe der Komplexe K1 bis K5, aus deren WH")}};
    if (k == Load)
        return {{QStringLiteral("title"), QStringLiteral("Bel.")}, {QStringLiteral("sub"), QString()},
                {QStringLiteral("first"), true}, {QStringLiteral("exercise"), 0}, {QStringLiteral("readOnly"), false},
                {QStringLiteral("tip"), QStringLiteral("Belastung der Woche: h (hoch), m (mittel), g (gesenkt)")}};
    if (k == Position)
        return {{QStringLiteral("title"), QStringLiteral("WK")}, {QStringLiteral("sub"), QString()},
                {QStringLiteral("first"), true}, {QStringLiteral("exercise"), 0}, {QStringLiteral("readOnly"), false},
                {QStringLiteral("tip"), QStringLiteral("Wettkampflage")}};
    const int e = exerciseOf(column);
    const QString title = e < 0 ? QStringLiteral("K%1").arg(-e) : QString::number(e);
    const QString unit = percent() && k != Wh ? QStringLiteral(" %") : QString();
    static const char *subs[] = {"WH", "MHG", "BW"};
    return {{QStringLiteral("title"), title},
            {QStringLiteral("sub"), QString::fromLatin1(subs[k]) + unit},
            {QStringLiteral("first"), k == Wh},
            {QStringLiteral("exercise"), e},
            {QStringLiteral("readOnly"), false},
            {QStringLiteral("tip"), e < 0 ? QStringLiteral("Komplex K%1").arg(-e) : Catalog::name(e)}};
}

QString ItpModel::rowLabel(int row) const
{
    if (row >= m_weeks)
        return QStringLiteral("Ø");
    const QDate monday = m_from.addDays(7 * row);
    QString phase;
    if (m_maz.peakPhase.isValid() && monday >= m_maz.peakPhase)
        phase = QStringLiteral(" L");
    else if (m_maz.buildUp.isValid() && monday >= m_maz.buildUp)
        phase = QStringLiteral(" A");
    return Weeks::label(monday) + phase;
}

QString ItpModel::rowMonday(int row) const
{
    return row < m_weeks ? m_from.addDays(7 * row).toString(Qt::ISODate) : QString();
}

QVariant ItpModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return {};
    if (orientation == Qt::Vertical)
        return rowLabel(section);
    const QVariantMap info = columnInfo(section);
    return info.value(QStringLiteral("title")).toString() + QLatin1Char(' ')
           + info.value(QStringLiteral("sub")).toString();
}

QHash<int, QByteArray> ItpModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"},
            {EditRole, "edit"},
            {AverageRole, "average"},
            {KindRole, "kind"},
            {ExerciseRole, "exercise"},
            {WarningRole, "warning"}};
}
