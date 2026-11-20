#include "youth.h"

#include <cmath>

namespace Youth {

int ageClass(const QDate &born, const QDate &at)
{
    return born.isValid() && at.isValid() ? at.year() - born.year() : 0;
}

bool limitedToOnePerWeek(int ageClass)
{
    return ageClass > 0 && ageClass <= 17;
}

QList<int> weightClassLimits(int sex, int ageClass)
{
    if (ageClass > 0 && ageClass <= 17)
        return weightClassLimits(sex);
    if (sex == 1)
        return {49, 53, 57, 61, 69, 77, 86};
    return {60, 65, 70, 75, 85, 95, 110};
}

QList<int> weightClassLimits(int sex)
{
    if (sex == 1)
        return {45, 49, 53, 57, 61, 69, 77};
    return {55, 60, 65, 70, 75, 85, 95};
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

namespace {

// AK 14 and AK 15: one total per kg of body weight, from the first row on;
// the last is the row above the table ("+102")
struct ByWeight
{
    int first;
    QList<int> ak14;
    QList<int> ak15;
};

const ByWeight &byWeight(int sex)
{
    static const ByWeight boys{35,
        {70, 72, 73, 74, 76, 77, 79, 80, 81, 83, 84, 85, 87, 88, 90, 90, 92, 94, 94, 96, 97, 99, 99,
         101, 102, 103, 105, 106, 107, 108, 110, 110, 112, 113, 114, 115, 117, 118, 119, 121, 121, 123,
         124, 125, 126, 128, 128, 130, 130, 132, 133, 134, 135, 137, 137, 139, 139, 141, 142, 143, 144,
         145, 146, 148, 148, 150, 150, 152, 153},
        {81, 83, 85, 86, 88, 90, 91, 92, 94, 96, 97, 99, 101, 103, 103, 105, 107, 108, 110, 112, 112,
         114, 116, 117, 119, 119, 121, 123, 124, 126, 127, 128, 130, 132, 132, 134, 135, 137, 138, 139,
         141, 142, 143, 145, 146, 148, 148, 150, 152, 153, 154, 155, 157, 158, 159, 161, 162, 163, 164,
         166, 167, 168, 170, 170, 172, 173, 174, 176, 177}};
    static const ByWeight girls{30,
        {55, 56, 57, 59, 59, 61, 63, 63, 65, 66, 67, 68, 70, 70, 72, 72, 74, 75, 76, 77, 78, 79, 81,
         81, 83, 83, 85, 85, 87, 88, 89, 90, 90, 92, 92, 94, 94, 96, 97, 98, 99, 100, 101, 101, 103,
         103, 105, 105, 107, 107, 108, 109, 110},
        {61, 63, 65, 66, 68, 69, 70, 72, 72, 74, 76, 77, 78, 79, 81, 81, 83, 85, 86, 87, 88, 90, 90,
         92, 93, 94, 96, 96, 98, 99, 100, 101, 103, 103, 105, 105, 107, 108, 109, 110, 112, 112, 114,
         114, 116, 117, 118, 119, 120, 121, 122, 123, 125}};
    return sex == 1 ? girls : boys;
}

// The weight rows' names: "35" ... "102", then "+102"
QString weightRow(const ByWeight &t, int i)
{
    const int rows = int(t.ak14.size());
    return i < rows - 1 ? QString::number(t.first + i) : QStringLiteral("+%1").arg(t.first + rows - 2);
}

} // namespace

QList<Norm> defaultDmNorms()
{
    QList<Norm> norms;
    for (int sex = 0; sex < 2; ++sex) {
        const ByWeight &t = byWeight(sex);
        for (int i = 0; i < t.ak14.size(); ++i)
            norms.append({sex, 14, weightRow(t, i), t.ak14[i]});
        for (int i = 0; i < t.ak15.size(); ++i)
            norms.append({sex, 15, weightRow(t, i), t.ak15[i]});
        const QList<int> limits = weightClassLimits(sex);
        const QList<int> totals = sex == 0 ? QList<int>{134, 142, 151, 159, 167, 184, 198, 206}
                                           : QList<int>{93, 98, 104, 110, 114, 125, 134, 139};
        for (int i = 0; i < limits.size(); ++i)
            norms.append({sex, 16, QStringLiteral("-%1").arg(limits[i]), totals[i]});
        norms.append({sex, 16, QStringLiteral("+%1").arg(limits.last()), totals.last()});
    }
    return norms;
}

bool dmAge(int ageClass)
{
    return ageClass >= 14 && ageClass <= 17;
}

int normGroup(int ageClass)
{
    return ageClass >= 16 ? 16 : ageClass;
}

QString normRow(int sex, int ageClass, double bodyWeight)
{
    if (bodyWeight <= 0)
        return QString();
    if (normGroup(ageClass) == 16)
        return weightClassFor(sex, bodyWeight);
    const ByWeight &t = byWeight(sex);
    const int i = qBound(0, int(std::ceil(bodyWeight - 1e-9)) - t.first, int(t.ak14.size()) - 1);
    return weightRow(t, i);
}

QList<Template> competitionTemplates()
{
    return {
        {QStringLiteral("DM Nachwuchs (AK 14–17)"), 1, QStringLiteral("November")},
        {QStringLiteral("DM Vereinsmannschaften Nachwuchs (AK 14–17)"), 1, QStringLiteral("November")},
        {QStringLiteral("DGJ-Supercup (AK 14–17)"), 0, QStringLiteral("März")},
        {QStringLiteral("DM Länderauswahlmannschaften (AK 14–17)"), 1, QStringLiteral("März")},
        {QStringLiteral("IDJM (AK 14–17)"), 2, QStringLiteral("Juni")},
        {QStringLiteral("DM Vereinsmannschaften Mehrkampf"), 1, QStringLiteral("Juni")},
        {QStringLiteral("Regionale Mehrkampfmeisterschaft"), 0, QString()},
        {QStringLiteral("Landesmeisterschaft"), 0, QString()},
    };
}

} // namespace Youth
