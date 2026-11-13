#include "youth.h"

namespace Youth {

int ageClass(const QDate &born, const QDate &at)
{
    return born.isValid() && at.isValid() ? at.year() - born.year() : 0;
}

bool limitedToOnePerWeek(int ageClass)
{
    return ageClass > 0 && ageClass <= 17;
}

QList<int> weightClassLimits(int sex)
{
    if (sex == 1)
        return {40, 45, 49, 55, 59, 64, 71, 76, 81};
    return {49, 55, 61, 67, 73, 81, 89, 96, 102};
}

QString weightClassFromLimit(int sex, int limit)
{
    const QList<int> limits = weightClassLimits(sex);
    if (limit <= 0)
        return QString();
    for (int l : limits) {
        if (limit <= l)
            return QStringLiteral("-%1").arg(l);
    }
    return QStringLiteral("+%1").arg(limits.last());
}

QString weightClassFor(int sex, double bodyWeight)
{
    if (bodyWeight <= 0)
        return QString();
    const QList<int> limits = weightClassLimits(sex);
    for (int l : limits) {
        if (bodyWeight <= l)
            return QStringLiteral("-%1").arg(l);
    }
    return QStringLiteral("+%1").arg(limits.last());
}

QList<Norm> defaultDmNorms()
{
    const int boys[] = {113, 128, 142, 153, 164, 173, 188, 195, 200, 205};
    const int girls[] = {45, 52, 59, 68, 75, 83, 92, 96, 100, 104};
    QList<Norm> norms;
    for (int sex = 0; sex < 2; ++sex) {
        const QList<int> limits = weightClassLimits(sex);
        const int *totals = sex == 0 ? boys : girls;
        for (int i = 0; i < limits.size(); ++i)
            norms.append({sex, QStringLiteral("-%1").arg(limits[i]), totals[i]});
        norms.append({sex, QStringLiteral("+%1").arg(limits.last()), totals[limits.size()]});
    }
    return norms;
}

bool dmJugendAge(int ageClass)
{
    return ageClass == 16 || ageClass == 17;
}

QList<Template> competitionTemplates()
{
    return {
        {QStringLiteral("DM Schüler (AK 13–15)"), 1, QStringLiteral("November")},
        {QStringLiteral("DM Jugend (AK 16–17)"), 1, QStringLiteral("Dezember")},
        {QStringLiteral("DGJ Schülerpokal (AK 12–14)"), 0, QStringLiteral("März")},
        {QStringLiteral("Schülerländerpokal (AK 12–14)"), 0, QStringLiteral("März")},
        {QStringLiteral("DM Vereinsmannschaften Schüler (AK 12–14)"), 1, QStringLiteral("März")},
        {QStringLiteral("DGJ Jugendpokal (AK 15–17)"), 0, QStringLiteral("März")},
        {QStringLiteral("Jugendländerpokal (AK 15–17)"), 0, QStringLiteral("März")},
        {QStringLiteral("Regionale Mehrkampfmeisterschaft (AK 15 und jünger)"), 0, QStringLiteral("Juni")},
        {QStringLiteral("IDJM (AK 15–17)"), 2, QStringLiteral("Juni")},
        {QStringLiteral("DM Vereinsmannschaften Jugend (AK 15–17)"), 1, QStringLiteral("Juni")},
        {QStringLiteral("Landesmeisterschaft"), 0, QString()},
    };
}

} // namespace Youth
