# Research: IDA, the RTK and the federation's documents

What three public sources confirm about the Trainingsplaner, where they
disagree with it, and what they suggest adding. Read in November 2026.

- **IDA manual**: "IDA Manual", BVDG, as of 18.05.2026, 19 pages. IDA
  ("Individuelle Datenanalyse", IAT, web, version 17.16) is the
  federation's successor to WinWoTA.
  <https://academy.german-weightlifting.de/wp-content/uploads/2026/05/IDA_Manual_Stand18.05.2026.pdf>
- **science-of-weightlifting.de downloads**:
  - Jugendsportprogramm 06/2025 (JSP)
  - Sportordnung 05/2025 (SPO)
  - Trainingsmittelkatalog 1996 and 2018 (TMK)
  - Linked from the site: RTK-Online (as of 07/2023) with the
    Rahmenorientierung PDFs MAZ_U13/U15/U17/U20 and the sample plans, and
    the IAT factsheet 07/2024.

  <https://www.science-of-weightlifting.de/downloads/>
- **Sandau (2018)**: "Modellierung der Zweikampf- und
  Körpergewichtsentwicklung im Gewichtheben", Leipziger
  Sportwissenschaftliche Beiträge 59(2), 161–171. Only the abstract and
  the appendix are online, so none of its figures could be read.

Not reached:
- the BVDG norm files "Stand 08/2026" (behind a download script);
- the JSP appendix (still "in Erstellung");
- the paper's pages 162–169.

No source gives the stored numbers of the week load: h = 3, m = 2, g = 1
is still unconfirmed (UX-PLAN question 8).

## 1. Confirmed

| What | Source |
|---|---|
| WH, MHG, BW, SG and Laststufe "kg/Wdh/Sätze", with a failed count per Laststufe | IDA p.10–15 |
| MHG = tonnage / WH, rounded half up (786/12 = 65.5 → 66) | IDA p.15, p.17 |
| Exercise numbers and groups K1–K10 as in `catalog.cpp` (1–45 identical) | TMK 1996, TMK 2018 |
| K1-7 and K1-5 as sums of the groups; AMKT apart; the header "K1-7: …Wh/…kg/…t" | IDA p.17, RO PDFs |
| RO in % of the competition target (MHG and BW in %, WH absolute) | IDA p.12, TMK 2018 "% Wettkampfziel" |
| ITP = RO % × target | IDA p.13 |
| Week load h/m/g: "hohe, mittlere, gesenkte Belastung" | RTK RO legend, IDA p.9, p.12 |
| The h/m/g sequences of the demo (U17: m h h g h h g h h g h m g) | RO U17 |
| Grundlagen-, Aufbau-, Leistungsausprägungsphase | RTK-Online, IDA p.9 |
| Plan/Ist (IDA: Soll/Ist) kept apart | IDA p.14–16 |
| Affiliations with a "seit" date | IDA p.6 |
| Analyse chart: MHG and BW as lines (kg), WH as bars | IDA p.19 |
| The week print: trainer, athlete, week, K summary, sessions | IDA p.17 |
| One competition a week for youth, age class by birth year | JSP p.4, SPO §9, §35 |
| The 75 sample-plan weeks in `tests/fixtures` (no newer RTK with other plans) | RTK-Online MTP PDFs |

IDA's own print example (p.17) adds Soll and Ist together in the K boxes.
Its K1-7 MHG (87 kg) does not match its own tonnage (46.1 t / 598 WH =
77 kg). Our way, Plan and Ist kept apart, is the right one.

## 2. Wrong or out of date in the Trainingsplaner

*Items 1–5 were fixed in November 2026. The classes are the IWF's from
1 August 2026, which are newer than the JSP's table below: U17 boys
55 60 65 70 75 85 95 +95, girls 45 49 53 57 61 69 77 +77. The DM
Nachwuchs norms (DGJ, status 08/2026) go by weight class for AK 16–17
and by kg of body weight for AK 14 and 15. The demo has the RTK's phases
and RO values, and Mira and Jonas are in −69 and −85.*

1. **Youth weight classes** (`src/youth.cpp`) are the classes from before
   2025. JSP 06/2025 p.5 has:

   | | Boys | Girls |
   |---|---|---|
   | U17 | −49 56 60 65 71 79 88 94 +94 | −44 48 53 58 63 69 77 +77 |
   | U15 | −52 56 60 65 71 79 88 +88 | −40 44 48 53 58 63 69 +69 |
   | U12 | −32 … −65, +65 | −28 … −63, +63 |

   The adult classes (SPO §9) are men 60…110/+110 and women 48…86/+86.
   The demo's weight class 64 for Mira at 63.4 kg is now −69.
2. **DGJ competitions** (JSP p.3):
   - DGJ-Supercup, AK 14–17, at the end of March;
   - IDJM, AK 14–17, at the end of June;
   - **DM Nachwuchs, AK 14–17, at the end of November.**

   The separate "DM Jugend AK 16–17, December" is gone. The norm applies
   to the whole DM Nachwuchs, AK 14–17 (`Youth::dmJugendAge`, the
   competition templates, HANDBUCH chapter 4).
3. **DM norms** belong to the old classes. The BVDG lists new norms "Stand
   08/2026", which have still to be fetched.
4. **Demo phases**:
   - The demo has 4/5/4 weeks (`demo.cpp`: Aufbau from week 5,
     Leistungsausprägung from week 10).
   - The RTK has **6/4/3** for U15 and U17 (Aufbau from week 7,
     Leistungsausprägung from week 11).
   - This changes the handbook's "Aufbauphase ab 42, Leistungsausprägung
     ab 47" to 44 and 48.
5. **Demo values**:
   - The snatch MHG of weeks 3, 4 and 13 is 71/73/84; the RO has 70/72/83.
   - The RTK RO has WH per K group, not per exercise. The handbook's
     "Reißen 16 WH … die Werte des Musterplans U17" mixes the sample plan's
     WH with the RO's percentages, so the wording needs fixing.
6. **The sample plans do not fill the RO.** U17 Verein reaches about 84 %
   of the RO's K1-7, U15 about 78 % and U20 about 108 %. U20's h/m/g order
   also differs from its RO. Nothing may assume sample plan = RO.

## 3. Improvements

Ordered by benefit to the coach against effort. Sizes: S up to a day,
M days, L a week or more.

### Data and rules (correctness first)

| # | Idea | Source | Size |
|---|---|---|---|
| 1 | Youth data from JSP 06/2025: weight classes U12/U15/U17 and adults, DGJ competitions, DM Nachwuchs norm for AK 14–17 | JSP p.3–5, SPO §9 | S |
| 2 | DM norms "Stand 08/2026" from the BVDG | BVDG Normen page | S, once fetched |
| 3 | Demo after the RTK: phases 6/4/3, RO MHG values, weight class −69, handbook text and pictures again | RO U17, RTK-Online | S |

### Planning

| # | Idea | Source | Size |
|---|---|---|---|
| 4 | **RTK templates** (done, November 2026; U20's phase lengths are not in the RTK): "Neuer MAZ aus RTK-Vorlage" U13 (6 weeks), U15, U17 (13), U20 (17), with h/m/g, LG/WK/HWK, WH per K group and MHG/BW % per exercise | MAZ_*.pdf | M |
| 5 | **RO per K group** (done, November 2026: WH per complex was there already; added K1-7 and K1-5 as sums, a single WH column per complex): a WH row per K1..K7 and week, compared in the ITP and the week summary | RO PDFs p.5 | M |
| 6 | **Scale values** (done, November 2026: "Skalieren" beside "Vorlage" in ITP and RO; weeks, WH/MHG/BW and a factor for the exercises the grid shows, kg to the weight step, percent whole, planned steps unchanged): chosen weeks and columns of the RO or ITP by a factor (e.g. −10 % after illness) | IDA p.11 | S–M |
| 7 | **RO proposal per ITP cell** (done, November 2026: an empty ITP cell shows it grey; Ctrl+Enter or a right click takes the cell, BW with its reps and sets, or the shown columns of a week, Bel. and WK too; Vorlage and the proposal share one conversion): the RO value shown grey, taken one cell or one row at a time, instead of Vorlage over everything | IDA p.13 | M |
| 8 | **TMK targets as caps** (done, November 2026: RO and ITP show such a value red with the reason, the RO for the youngest of its MAZ; Reißen and Stoßen are free in a WK/HWK week, and the RTK's four ROs stay within the TMK in every training week): warn when a planned BW % is above the TMK value for the athlete's stage, or K4/K6 is used below its age | TMK 2018 | S–M |
| 9 | **Volume norms per stage** (done, November 2026: a dashed line over the WH bars of the Belastungsverlauf, a step where the age changes, and the norm per complex in the grid's column tips; the RTK's ROs meet it on average, U13 201, U15 289, U17 358, U20 299) as a reference line (K1-7: 200/280/350/300/320/300 WH a week; 350 the upper limit in U17) | TMK 2018, RTK-Online | S |
| 10 | Countdown "Tr.-Wo." to the main competition, LG/WK/HWK per week in ITP, month and Belastungsverlauf | RO PDFs | S |
| 11 | Plan phases and h/m/g as bands in the month view | IDA p.9 | S–M |
| 12 | Planned set size (SG) in RO and ITP. First check whether WinWoTA had it | IDA p.10–12 | M |

### Week plan and print

| # | Idea | Source | Size |
|---|---|---|---|
| 13 | Print: tonnage per exercise line, AMKT WH in the header, creation date | IDA p.17 | S |
| 14 | "Letzter Eintrag": jump to the last week with data | IDA p.14 | S |
| 15 | A note per exercise line, not only per session | IDA p.15 | S–M |
| 16 | Colour per K group on the lines of week and month | IDA p.15–16 | S |
| 17 | Further calendar entries: Lehrgang, Diagnostik/Test, with a type filter | IDA p.14 | M |

### Analysis

| # | Idea | Source | Size |
|---|---|---|---|
| 18 | **Best weight per set size** (BW at 1…10 reps) per exercise over a period | IDA p.18 | S–M |
| 19 | "Min zum WoBW": count only reps at or above X % of the week's best | IDA p.18 | M |
| 20 | "Anw": in how many sessions a week an exercise appears | IDA p.18 | S |
| 21 | Quick ranges (1/2/4 weeks, 1/3/6 months); Plan and Ist in one chart | IDA p.19 | S |
| 22 | Compare one athlete with the **average of a group** | IDA p.19 | M |
| 23 | **Development curve**: a Gompertz fit of the total over age in the competition chart, one to two years ahead with a band; the same for body weight against the class limits | Sandau 2018 | S–M |
| 24 | Plausibility of a MAZ target against that curve (a hint, never a block); proposed target instead of a flat "max + 4" | Sandau 2018 | S |
| 25 | Intensity bands: Schnellkraft 55–100 %, Maximalkraft 65–110 % of the competition target | RTK-Online ABT | S |

### Athletes and youth

| # | Idea | Source | Size |
|---|---|---|---|
| 26 | Stage (Etappe) per athlete with recommended sessions per week; Datenprüfung flags weeks outside | TMK 2018, factsheet | S |
| 27 | IAT points and the athletic tests (Sternlauf, Kugelschocken, Schlussdreisprung) | JSP p.8–11 | M |
| 28 | Sitting and standing height in the Zusatzinfo (maturity) | JSP p.4 | M |
| 29 | Affiliations Landesverband, BSP, Verein (Mannschaft); an active/inactive status | IDA p.6 | S |
| 30 | Athlete list for printing (birth date, AK, Kader, Verein, class, bests) | IDA p.5 | S |
| 31 | Inline required-field messages in the MAZ and athlete forms | IDA p.8 | S |

## 4. Not worth taking from IDA

The coach left IDA for WinWoTA's way of working (UX-PLAN §8), so the
following stay out:

- the hourly event calendar instead of the day × TE grid;
- the compulsory "Bestätigen" for an Ist;
- the free five-level plan hierarchy with a schema that cannot be
  changed afterwards;
- grids of over 300 columns;
- h/m/g as text in a section's name;
- saving by hand;
- logins and rights;
- totals that add Soll and Ist together;
- choosing a category and then the exercise from two dropdowns instead
  of typing the number.

## 5. Still open

- The stored numbers of h/m/g. Only the old PC can tell (Phase 0).
- Which target each exercise's percentage refers to, and the rounding of
  the ITP. IDA's manual says nothing about either.
- K10 numbering: TMK 1996 and 2018 differ for 50–59. WinWoTA's numbering
  decides.
- The reference figures of Sandau (2018). They need the printed journal,
  or Huebner & Perperoglou (2019, Frontiers in Physiology 10:1121) as an
  open alternative.
