#pragma once

#include <QList>
#include <QString>

// The Rahmenorientierungen of the BVDG's Rahmentrainingskonzeption 2019
// (RTK-Online, status July 2023) as templates for a new MAZ: U13 with 6
// weeks, U15 and U17 with 13, U20 with 17. Per week the load, LG/WK/HWK,
// the WH of K1..K7 and per exercise MHG and BW in percent of the target
// with the reps and sets at BW. The data is rtk/rtk-ro.json, made from
// the PDFs by rtk/extract_rtk_ro.py.
namespace Rtk {

struct Template
{
    QString key;     // "U17"
    QString title;   // "RTK U17 (13 Wochen)"
    int weeks = 0;
    int buildUp = 0; // week the Aufbauphase begins (1 = the first), 0 none
    int peak = 0;    // week the Leistungsausprägung begins, 0 none
};

QList<Template> templates();
Template find(const QString &key);

// Writes the template into the RO of a MAZ, its first week at the MAZ's
// first; as many weeks as both have. Meant for a new MAZ: what is in the
// RO in those weeks stays unless the template sets it.
bool fillRo(const QString &mazId, const QString &key);

} // namespace Rtk
