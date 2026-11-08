#include "itpmodel.h"

#include "catalog.h"

ItpModel::ItpModel(QObject *parent) : QAbstractTableModel(parent) {}

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
    m_weeks = v;
    reload();
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
    m_exercises = list;
    reload();
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

void ItpModel::reload()
{
    beginResetModel();
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
    endResetModel();
    emit configChanged();
}

int ItpModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() || m_weeks == 0 ? 0 : m_weeks + 1;
}

int ItpModel::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_exercises.size()) * 3 + 2;
}

ItpModel::Kind ItpModel::kindOf(int column) const
{
    const int n = int(m_exercises.size()) * 3;
    if (column >= n)
        return column == n ? Load : Position;
    return Kind(column % 3);
}

int ItpModel::exerciseOf(int column) const
{
    return column < m_exercises.size() * 3 ? m_exercises.at(column / 3) : 0;
}

int ItpModel::value(int row, int column) const
{
    const QDate monday = m_from.addDays(7 * row);
    const Kind k = kindOf(column);
    if (k == Load)
        return m_meta.value(monday).load;
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
    case Qt::DisplayRole:
    case EditRole: {
        if (average) {
            if (k == Position)
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
    const QString text = value.toString().trimmed();
    bool ok = true;
    if (k == Load || k == Position) {
        WeekMeta m = m_meta.value(monday);
        m.monday = monday;
        if (k == Load)
            m.load = qBound(0, text.toInt(), 99);
        else
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
        const QModelIndex avg = this->index(m_weeks, index.column());
        emit dataChanged(avg, avg);
    }
    return ok;
}

QVariantMap ItpModel::columnInfo(int column) const
{
    const Kind k = kindOf(column);
    if (k == Load)
        return {{QStringLiteral("title"), QStringLiteral("Bel.")}, {QStringLiteral("sub"), QString()},
                {QStringLiteral("first"), true}, {QStringLiteral("exercise"), 0},
                {QStringLiteral("tip"), QStringLiteral("Belastung der Woche")}};
    if (k == Position)
        return {{QStringLiteral("title"), QStringLiteral("WK")}, {QStringLiteral("sub"), QString()},
                {QStringLiteral("first"), true}, {QStringLiteral("exercise"), 0},
                {QStringLiteral("tip"), QStringLiteral("Wettkampflage")}};
    const int e = exerciseOf(column);
    const QString title = e < 0 ? QStringLiteral("K%1").arg(-e) : QString::number(e);
    const QString unit = percent() && k != Wh ? QStringLiteral(" %") : QString();
    static const char *subs[] = {"WH", "MHG", "BW"};
    return {{QStringLiteral("title"), title},
            {QStringLiteral("sub"), QString::fromLatin1(subs[k]) + unit},
            {QStringLiteral("first"), k == Wh},
            {QStringLiteral("exercise"), e},
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
            {ExerciseRole, "exercise"}};
}
