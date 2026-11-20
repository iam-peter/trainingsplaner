#include "tmk.h"

#include "catalog.h"

namespace Tmk {

namespace {

// The TMK 2018 by exercise and stage (Kinder, Schüler, Jugend, Junioren,
// U23, Senioren). K1-K7: BW in percent of the competition target, "/SG"
// the set size at it, a range "99-101", ">100" without a cap. K8 and K9
// give WH and set sizes, not percent: "+" allowed. "-" a hatched cell,
// not for the stage. Halbkniebeuge (21) is hatched in every stage.
struct Row
{
    int exercise;
    const char *cells[6];
};

const Row table[] = {
    {1, {"90/3", "95/2", "97", "99-101", "99-101", "99-101"}},
    {2, {"-", "-", "100", "102", "102", "102"}},
    {3, {"90/2", "95/2", "97", "100", "98-100", "98-100"}},
    {4, {"85/3", "90/3", "95/2", "97/2", "102", "102"}},
    {5, {"85/3", "95/2", "100", "102", "104", "104"}},
    {6, {"80/3", "85/3", "92/2", "97/2", "102", "102"}},
    {7, {"-", "-", "82/2", "85/2", "90", "90"}},
    {8, {"60/3", "65/3", "70/2", "75/2", "80", "80"}},
    {9, {"80/3", "85/3", "92/2", "97/2", "102", "102"}},
    {10, {"-", "-", "-", "80/2", "85", "85"}},
    {11, {"60/3", "65/3", "70/2", "75/2", "80", "80"}},
    {12, {"85/3", "95/2", "100", "102", "104", "104"}},
    {13, {"-", "90/3", "97/3", "103/3", "108", "108"}},
    {14, {"-", "90/3", "95/3", "100/3", "105", "105"}},
    {15, {"-", "-", "-", "113/3", "125", "130"}},
    {16, {"-", "-", "-", "110/3", "120", "125"}},
    {17, {"-", "-", "-", "120", "130", "140"}},
    {18, {"-", "85/3", "95/2", "105", "110", "110"}},
    {19, {"90/5", "95/3", "100/3", "103/3", "105/3", "105/3"}},
    {20, {"-", "100/5", "112/3", "117/3", "120/3", "120/3"}},
    {21, {"-", "-", "-", "-", "-", "-"}},
    {22, {"-", "-", "80/3", "85/2", "90", "90"}},
    {23, {"-", "-", "-", "65/2", "80", "80"}},
    {24, {"-", "-", "70/3", "75/2", "80", "80"}},
    {25, {"-", "-", "40/5", "50/3", "60", "60"}},
    {26, {"-", "-", "75/2", "80/2", "85", "85"}},
    {27, {"80/3", "85/2", "90", "95", "100", "100"}},
    {28, {"-", "-", "-", "80", "85", "85"}},
    {29, {"80/3", "85/2", "90", "95", ">100", ">100"}},
    {30, {"-", "+", "+", "+", "+", "+"}},
    {31, {"+", "+", "+", "+", "+", "+"}},
    {32, {"-", "+", "+", "+", "+", "+"}},
    {33, {"+", "+", "+", "+", "+", "+"}},
    {34, {"-", "-", "+", "+", "+", "+"}},
    {35, {"-", "-", "+", "+", "+", "+"}},
    {36, {"+", "+", "+", "+", "+", "+"}},
    {37, {"+", "+", "+", "+", "+", "+"}},
    {38, {"+", "+", "+", "+", "+", "+"}},
    {39, {"+", "+", "+", "+", "+", "+"}},
    {40, {"-", "+", "+", "+", "+", "+"}},
    {41, {"-", "+", "+", "+", "+", "+"}},
    {42, {"-", "+", "+", "+", "+", "+"}},
    {43, {"-", "+", "+", "+", "+", "+"}},
    {44, {"-", "+", "+", "+", "+", "+"}},
    {45, {"+", "+", "+", "+", "+", "+"}},
};

Entry parse(const QString &cell)
{
    Entry e;
    if (cell == QLatin1String("-")) {
        e.allowed = false;
        return e;
    }
    if (cell == QLatin1String("+") || cell.startsWith(QLatin1Char('>')))
        return e;
    e.text = cell;
    // "99-101": up to the upper end; "95/2": the BW before the set size
    const QString bw = cell.section(QLatin1Char('/'), 0, 0);
    e.bw = bw.section(QLatin1Char('-'), -1).toInt();
    return e;
}

} // namespace

Stage stage(int ageClass)
{
    if (ageClass <= 13)
        return Kinder;
    if (ageClass <= 15)
        return Schueler;
    if (ageClass <= 17)
        return Jugend;
    if (ageClass <= 20)
        return Junioren;
    if (ageClass <= 23)
        return U23;
    return Senioren;
}

QString stageName(Stage s)
{
    switch (s) {
    case Kinder:
        return QStringLiteral("Kinder (bis AK 13)");
    case Schueler:
        return QStringLiteral("Schüler (AK 14–15)");
    case Jugend:
        return QStringLiteral("Jugend (AK 16–17)");
    case Junioren:
        return QStringLiteral("Junioren (AK 18–20)");
    case U23:
        return QStringLiteral("U23 (AK 21–23)");
    case Senioren:
        break;
    }
    return QStringLiteral("Senioren (ab AK 24)");
}

Entry entry(int exercise, Stage s)
{
    if (exercise < 0) {
        Entry complex;
        complex.allowed = false;
        for (const Exercise &e : Catalog::all()) {
            if (e.group == -exercise && entry(e.id, s).allowed)
                complex.allowed = true;
        }
        return complex;
    }
    for (const Row &r : table) {
        if (r.exercise == exercise)
            return parse(QString::fromUtf8(r.cells[s]));
    }
    return {};
}

QString notForStage(int exercise, Stage s)
{
    if (entry(exercise, s).allowed)
        return {};
    const QString name = exercise < 0 ? QStringLiteral("K%1").arg(-exercise) : Catalog::name(exercise);
    return QStringLiteral("%1 ist im TMK 2018 nicht für %2 vorgesehen.").arg(name, stageName(s));
}

bool exemptInCompetition(int exercise, const QString &position)
{
    const QString p = position.trimmed().toUpper();
    return (exercise == 1 || exercise == 3) && (p == QLatin1String("WK") || p == QLatin1String("HWK"));
}

} // namespace Tmk
