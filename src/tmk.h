#pragma once

#include <QString>

// The Trainingsmittelkatalog für den LLA im Gewichtheben of BVDG and IAT
// (2018): per age stage the highest best weight (BW) of each exercise in
// percent of the competition target, with the set size at it, and the
// exercises and complexes not meant for the stage yet. The program uses
// it as a cap on what is planned. The RTK's framework plans stay within
// it, but for the competition itself.
namespace Tmk {

// The stages by age class (the TMK's "chronologisches Alter")
enum Stage { Kinder, Schueler, Jugend, Junioren, U23, Senioren };
Stage stage(int ageClass);
// "Schüler (AK 14–15)"
QString stageName(Stage s);

struct Entry
{
    bool allowed = true; // false: not for the stage (hatched in the TMK)
    int bw = 0;          // highest BW in percent of the target, 0 none
    QString text;        // the TMK's cell: "95/2" (BW/SG), "99-101"
};
// An exercise (1..45), or a complex (-1..-7): allowed when one of its
// exercises is
Entry entry(int exercise, Stage s);

// "Lastheben breit ist im TMK 2018 nicht für Jugend (AK 16–17)
// vorgesehen."; "" when it is
QString notForStage(int exercise, Stage s);

// The TMK's weekly volume of a stage as a reference: the WH a week of a
// complex (-1..-6), or of K1-7 for 0; 0 when the TMK gives none (K7 is
// optional). It is the average over a cycle, as the RTK's framework plans
// show, not a cap on each week.
int weeklyWh(int complex, Stage s);

// Reißen and Stoßen in a week with a competition (WK-Lage "WK" or "HWK"):
// the competition goes to 100 % and more, so no cap
bool exemptInCompetition(int exercise, const QString &position);

// The training stages (Trainingsetappen) of the BVDG's long-term build-up
// by age class, with the training sessions a week, after the IAT's
// factsheet (2024): AGA up to AK 13 (2-3 a week, from the TMK 2018, the
// factsheet gives none), GLT 14-15 (3-5), ABT 16-17 (5-7), AST 18-23 and
// HLT from 24 (7-9). Up to AK 17 the TMK 2018 says the same; from 18 on
// it said 6-8.
struct Etappe
{
    QString code;    // "ABT"
    QString name;    // "Aufbautraining"
    int minSessions = 0;
    int maxSessions = 0;
};
// None (empty code) without an age class
Etappe etappe(int ageClass);
// "ABT (Aufbautraining), 5–7 Trainingseinheiten je Woche"; "" without one
QString etappeText(int ageClass);

} // namespace Tmk
