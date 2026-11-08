#include "catalog.h"

namespace {

using E = Exercise;

const QList<Exercise> kCatalog = {
    {1, QStringLiteral("Reißen WKÜ"), E::Snatch, 1, E::Weights},
    {2, QStringLiteral("Reißen mit Bändern"), E::Snatch, 1, E::Weights},
    {3, QStringLiteral("Stoßen WKÜ"), E::CleanAndJerk, 1, E::Weights},
    {4, QStringLiteral("Umsetzen"), E::CleanAndJerk, 1, E::Weights},
    {5, QStringLiteral("Ausstoßen"), E::CleanAndJerk, 1, E::Weights},
    {6, QStringLiteral("Reißen erhöhte Position"), E::Snatch, 2, E::Weights},
    {7, QStringLiteral("Standreißen"), E::Snatch, 2, E::Weights},
    {8, QStringLiteral("Umgruppieren breit"), E::Snatch, 2, E::Weights},
    {9, QStringLiteral("Umsetzen erhöhte Position"), E::CleanAndJerk, 2, E::Weights},
    {10, QStringLiteral("Standumsetzen"), E::CleanAndJerk, 2, E::Weights},
    {11, QStringLiteral("Umgruppieren eng"), E::CleanAndJerk, 2, E::Weights},
    {12, QStringLiteral("Standstoßen"), E::CleanAndJerk, 2, E::Weights},
    {13, QStringLiteral("Zug breit"), E::Snatch, 3, E::Weights},
    {14, QStringLiteral("Zug eng"), E::CleanAndJerk, 3, E::Weights},
    {15, QStringLiteral("Lastheben breit"), E::Snatch, 4, E::Weights},
    {16, QStringLiteral("Lastheben eng"), E::CleanAndJerk, 4, E::Weights},
    {17, QStringLiteral("Anstoßkniebeuge"), E::CleanAndJerk, 4, E::Weights},
    {18, QStringLiteral("Reißkniebeuge"), E::Snatch, 5, E::Weights},
    {19, QStringLiteral("Kniebeuge vorn"), E::CleanAndJerk, 5, E::Weights},
    {20, QStringLiteral("Kniebeuge hinten"), E::CleanAndJerk, 5, E::Weights},
    {21, QStringLiteral("Halbkniebeuge"), E::CleanAndJerk, 5, E::Weights},
    {22, QStringLiteral("Powerzug breit"), E::Snatch, 6, E::Weights},
    {23, QStringLiteral("Kraftreißen"), E::Snatch, 6, E::Weights},
    {24, QStringLiteral("Powerzug eng"), E::CleanAndJerk, 6, E::Weights},
    {25, QStringLiteral("Kraftdrücken"), E::CleanAndJerk, 6, E::Weights},
    {26, QStringLiteral("Schwungdrücken"), E::CleanAndJerk, 6, E::Weights},
    {27, QStringLiteral("Umsetzen + Kniebeuge vorn"), E::CleanAndJerk, 7, E::Weights},
    {28, QStringLiteral("Standumsetzen/-stoßen"), E::CleanAndJerk, 7, E::Weights},
    {29, QStringLiteral("Kniebeuge vorn + Ausstoßen"), E::CleanAndJerk, 7, E::Weights},
    {30, QStringLiteral("Nackendrücken"), E::General, 8, E::Weights},
    {31, QStringLiteral("Bankdrücken"), E::General, 8, E::Weights},
    {32, QStringLiteral("Beugestütze"), E::General, 8, E::Text},
    {33, QStringLiteral("Klimmzüge"), E::General, 8, E::Text},
    {34, QStringLiteral("Beindrücken Herkules"), E::General, 8, E::Weights},
    {35, QStringLiteral("Beindrücken im Liegen"), E::General, 8, E::Weights},
    {36, QStringLiteral("Zug im Liegen"), E::General, 8, E::Weights},
    {37, QStringLiteral("Bauchmuskel"), E::General, 8, E::Text},
    {38, QStringLiteral("Rückenmuskel"), E::General, 8, E::Text},
    {39, QStringLiteral("Beinbeuger Maschine"), E::General, 9, E::Text},
    {40, QStringLiteral("Gesäß Maschine"), E::General, 9, E::Text},
    {41, QStringLiteral("Rücken Maschine"), E::General, 9, E::Text},
    {42, QStringLiteral("Latissimus Maschine"), E::General, 9, E::Text},
    {43, QStringLiteral("Delta Maschine"), E::General, 9, E::Text},
    {44, QStringLiteral("Beinstrecker Maschine"), E::General, 9, E::Text},
    {45, QStringLiteral("weitere AMKT-Übungen"), E::General, 9, E::Text},
};

} // namespace

namespace Catalog {

const QList<Exercise> &all()
{
    return kCatalog;
}

const Exercise *find(int id)
{
    for (const Exercise &e : kCatalog) {
        if (e.id == id)
            return &e;
    }
    return nullptr;
}

QString name(int id)
{
    const Exercise *e = find(id);
    return e ? e->name : QString();
}

bool isWeightExercise(int id)
{
    const Exercise *e = find(id);
    return e && e->input == Exercise::Weights;
}

} // namespace Catalog
