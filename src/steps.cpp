#include "steps.h"

#include <QLocale>
#include <QStringList>
#include <QtMath>

#include <cmath>

QString Stats::bwRepsSets() const
{
    if (bw == 0)
        return QString();
    return QStringLiteral("%1/%2").arg(bwReps).arg(bwSets);
}

QString Stats::summary() const
{
    const QLocale de(QLocale::German);
    return QStringLiteral("%1Wh / %2kg / %3t")
        .arg(wh)
        .arg(mhg)
        .arg(de.toString(tonnage / 1000.0, 'f', 1));
}

namespace Steps {

QList<Step> parse(const QString &text)
{
    QList<Step> steps;
    const QStringList parts = text.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    for (const QString &raw : parts) {
        const QString p = raw.trimmed();
        if (p.size() != 9)
            continue;
        bool ok[4] = {};
        Step s;
        s.kg = p.mid(0, 3).toInt(&ok[0]);
        s.reps = p.mid(3, 3).toInt(&ok[1]);
        s.sets = p.mid(6, 2).toInt(&ok[2]);
        s.failed = p.mid(8, 1).toInt(&ok[3]);
        if (ok[0] && ok[1] && ok[2] && ok[3] && !s.isEmpty())
            steps.append(s);
    }
    return steps;
}

QString format(const QList<Step> &steps)
{
    QStringList parts;
    for (const Step &s : steps) {
        if (s.isEmpty())
            continue;
        parts.append(QStringLiteral("%1%2%3%4")
                         .arg(qBound(0, s.kg, 999), 3, 10, QLatin1Char('0'))
                         .arg(qBound(0, s.reps, 999), 3, 10, QLatin1Char('0'))
                         .arg(qBound(0, s.sets, 99), 2, 10, QLatin1Char('0'))
                         .arg(qBound(0, s.failed, 9)));
    }
    return parts.join(QLatin1Char(';'));
}

Stats compute(const QList<Step> &steps)
{
    Stats st;
    for (const Step &s : steps) {
        const int reps = s.reps * s.sets;
        st.wh += reps;
        st.tonnage += double(s.kg) * reps;
        if (s.kg > st.bw) {
            st.bw = s.kg;
            st.bwReps = s.reps;
            st.bwSets = s.sets;
        } else if (s.kg == st.bw && s.kg > 0) {
            if (s.reps == st.bwReps) {
                st.bwSets += s.sets;
            } else if (s.reps > st.bwReps) {
                st.bwReps = s.reps;
                st.bwSets = s.sets;
            }
        }
    }
    if (st.wh > 0)
        st.mhg = qRound(st.tonnage / st.wh);
    return st;
}

int nextWeight(int kg, double step, int direction)
{
    if (step <= 0)
        step = 1;
    auto kgAt = [step](long m) { return int(std::floor(m * step + 1e-9)); };
    long m;
    if (direction > 0) {
        m = long(std::floor(kg / step));
        while (kgAt(m) <= kg)
            ++m;
    } else {
        m = long(std::ceil(kg / step));
        while (m > 0 && kgAt(m) >= kg)
            --m;
    }
    return qBound(0, kgAt(m), 999);
}

} // namespace Steps
