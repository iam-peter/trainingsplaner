# Trainingsplaner

Weekly training planning for weightlifting coaches: week plans, the load
figures WH, MHG and BW, and printed plans.

**[Website](https://iam-peter.github.io/trainingsplaner/)** ·
**[Download](https://github.com/iam-peter/trainingsplaner/releases)** ·
[Nightly](https://github.com/iam-peter/trainingsplaner/releases/tag/nightly)

![Week plan](docs/screenshots/week.png)

Built with Qt 6 (C++ and Qt Quick); data lives in a single SQLite file.
The user interface is in German.

## Download

Each [release](https://github.com/iam-peter/trainingsplaner/releases) has:

| File | For |
|---|---|
| `trainingsplaner-windows-x64-setup.exe` | Windows 10/11: installer, no administrator rights needed |
| `trainingsplaner-windows-x64.zip` | Windows 10/11 without installing: unzip, start `trainingsplaner.exe` |
| `trainingsplaner-macos.dmg` | macOS, Apple silicon and Intel |
| `trainingsplaner-linux-x64.AppImage` | any Linux |
| `trainingsplaner-linux-x64.deb` | Debian and Ubuntu, with its own Qt |

The programs aren't signed: Windows SmartScreen asks once (*Weitere
Informationen*, *Trotzdem ausführen*). macOS blocks the first start; then
choose *Dennoch öffnen* under System Settings › Privacy & Security.

**Windows installer.** It puts the program into a fixed folder
(`%LOCALAPPDATA%\Programs\Trainingsplaner`, or Program Files when
installed for all users), offers two checkboxes for a Start menu entry
and a desktop shortcut (both ticked) and registers an uninstaller under
Windows' *Apps*. The uninstaller offers a checkbox to delete the data as
well (unticked). Step-by-step guides for every system are on the
[website](https://iam-peter.github.io/trainingsplaner/#installation).

**Updates.** At start, at most once a day, the program asks GitHub for the
latest release and shows a bar when there is a newer one. Installed with
the Windows installer, *Jetzt aktualisieren* downloads the new installer,
checks its SHA-256 against the one GitHub publishes, runs it silently and
starts the new version. On macOS, Linux and from the zip it opens the
download. The training data stays in the user's profile and survives
updates and uninstalling.

## Features

- **Wochenplan**: 7 days × 2 (optionally 3) sessions per athlete, plan or
  actual ("Ist"), week note and injured flag, K1–K7 weekly summary,
  copy/paste a whole week (also to another athlete), calendar to pick a
  week, extra info per day (body weight, body fat, supplements).
- **Session editor**: weight exercises (kg, reps per set "SG", sets "ANZ",
  failed attempts "UG" in actual weeks), general exercises as text with total
  reps, free text lines, times and a note. Live MHG/BW/WH/SG-ANZ for the
  session and the whole week. History and chart of an exercise.
- **Erfassung TÜ**: click an exercise line in the week to edit that
  exercise across the whole week: one row per session with its weight
  steps, move it to another day or session, add or remove it, copy weight
  steps between rows, with the week's totals and the ITP targets.
- **Sportler**: athletes with age, and Kader, Verein, BSP, Bundeswehr and
  trainers with their history over time; a filter by Kader and sex.
- **Wettkämpfe**: results with six attempts (valid/invalid), total, and a
  chart over the years with best results per half year or year, trends
  and the reference total of the athlete's class.
- **Planung**: macrocycles (MAZ) with phases and athletes' targets, the
  framework plan (RO) in percent, the individual training plan (ITP) per
  week and exercise or group, planned weight steps, templates (RO to ITP
  with the athlete's targets), and a chart of ITP against plan or actual.
- **Analyse**: section analysis (WH, MHG, BW, set size with totals and
  trends, in kg or percent of the targets, comparisons, all MAZ, reps per
  weight), group analysis of a MAZ, data check, and charts.
- **Data**: import and export in the old program's format (everything,
  changes since a date including deletions, or one athlete's weeks).
- **Print / PDF** of the week plan with the old print options (notation,
  figures, notes, empty lines, fonts, margins, landscape, logo), and of
  all analyses and charts; charts also as PNG images, with the values
  shown on hover.
- **Everyday use**: keyboard shortcuts (arrow keys, Enter and Delete in
  the week grid, Ctrl+←/→ for weeks, Ctrl+C/V for sessions), undo and
  redo of every change to sessions, a right-click menu with "Ist = Plan",
  one athlete selection for all pages, light and dark mode, help with a
  glossary (F1), and example data to try the program on the first start.

![Planning](docs/screenshots/planning.png)

What comes next: [docs/ROADMAP.md](docs/ROADMAP.md).

## Data from WinWoTA XP

Users of the older WinWoTA XP 2.61 can bring their data along: export it
there ("Datenexport", option *komplett*, gives `winwotaxp.bak`), then use
**Daten importieren…** here. The exercise numbers are the same. Rows are
merged by key and timestamp, so importing again is safe.

This is an independent project. It is not affiliated with, endorsed by or
derived from the code of IAT Leipzig, the BVDG or WinWoTA; the names only
describe which program and data format can be imported.

## Building

Requires Qt 6.8 or newer with the modules Quick, QuickControls2, Sql
(SQLite driver), PrintSupport and Widgets, plus CMake 3.21+.

```bash
qt-cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build
```

For Windows, install Qt with the online installer (MSVC 2022 or MinGW),
open `CMakeLists.txt` in Qt Creator and build *Release*. `windeployqt
--qmldir qml trainingsplaner.exe` makes the folder self-contained.

The database is stored at
`%APPDATA%\Trainingsplaner\Trainingsplaner\trainingsplaner.sqlite`
(shown under *Einstellungen*). To back up, close the program and copy that
file.

## Releases

| Workflow | What it does |
|---|---|
| **CI** | builds and tests every push and pull request on Linux |
| **Nightly** | every night with new commits (or by hand): builds and tests on Linux, Windows and macOS, builds the Windows installer (`packaging/windows/trainingsplaner.iss`, Inno Setup) and tests installing, the update check and uninstalling, then replaces the `nightly` pre-release |
| **Promote Release** | run by hand with a version such as `0.2.0`: publishes the current nightly's files as release `v0.2.0` |
| **Website** | publishes `pages/` on GitHub Pages; the page finds the newest release and nightly by itself |

To release: bump `project(... VERSION ...)` in `CMakeLists.txt`, wait for
(or start) the nightly, then run *Promote Release*.

## Command line

| Option | Purpose |
|---|---|
| `--db <file>` | use another database file |
| `--import <file.bak>` | import an old data export and exit |
| `--athlete <id> --week 46/2026` | start with this athlete and week |
| `--page sportler\|planung\|analyse\|wettkaempfe\|einstellungen` | start on that page |
| `--open 1:2`, `ex:8`, `hist:8`, `chart:8` | open a session (day:number), an exercise's week, history or chart |
| `--page planung --open maz\|itp\|ro\|laststufen`, `--page analyse --open individual\|group\|check\|chart` | open a tab |
| `--farbschema hell\|dunkel` | light or dark colours regardless of the system |
| `--grab <file.png>` | save a screenshot and exit (for testing) |
| `--check-update` | print the latest release and exit (0 found, 2 GitHub answered without one, 1 unreachable) |

## Code layout

| Path | Content |
|---|---|
| `src/catalog.*` | exercise catalogue (numbers, groups, names) |
| `src/steps.*` | weight step encoding and the load figures |
| `src/model.h` | athletes, sessions, entries, weeks, weekly summary |
| `src/database.*` | SQLite storage |
| `src/tables.*` | table definitions shared by import, export and the deletion log |
| `src/bakimport.*`, `src/bakexport.*` | import and export in the old program's format |
| `src/exerciseweek.*` | one exercise across a week (Erfassung TÜ) |
| `src/competition.*` | competitions, totals, best results, reference totals |
| `src/planning.*` | MAZ, framework plan, ITP, planned weight steps |
| `src/analysis.*` | section analysis and load tables |
| `src/weekreport.*` | printed / PDF week plan |
| `src/store.*`, `src/planstore.*`, `src/analysisapi.*`, `src/itpmodel.*` | APIs and models for the QML user interface |
| `qml/` | user interface |
| `tests/` | unit tests (`tst_core`) and UI tests (`tst_qml`) |
| `logo/` | icon and desktop entry |
| `fonts/`, `icons/` | Inter, JetBrains Mono and Lucide icons, built into the program |
| `packaging/` | Debian package script |
| `pages/` | website |
| `docs/screenshots/` | screenshots with invented demo data |
| `.github/workflows/` | CI, nightly, release and website |

### Old storage format

Weight steps are stored in `te_ueb.lststbem` as nine-digit blocks separated
by `;`: `KKK RRR SS F` = kg, reps per set, sets, failed attempts. Example:
`012003030;015003020` = 12 kg 3×3, 15 kg 3×2 → WH 15, MHG 13, BW 15 (3/2).

## Data protection

The program stores personal data of athletes (names, dates of birth,
training). That data stays in the local database file and is never part of
this repository: `.gitignore` excludes data exports (`*.bak`), databases and
generated PDFs. Tests use invented athletes only. When reporting a problem,
do not attach a real database or export.

The only network access is the update check, which sends no training data:
GitHub sees the program version (as user agent) and the IP address. It can
be switched off under Einstellungen › Allgemein.

## Licence

MIT, see [LICENSE](LICENSE). The bundled assets keep their own licences:

- Fonts: [Inter](https://rsms.me/inter/) and
  [JetBrains Mono](https://www.jetbrains.com/lp/mono/), SIL Open Font
  License 1.1 (`fonts/`).
- Icons: [Lucide](https://lucide.dev/), ISC licence (`icons/LICENSE.txt`).

The program uses [Qt](https://www.qt.io/) under the LGPL v3. When handing
out a Windows build made with `windeployqt`, Qt stays in separate DLLs as the
LGPL requires; add Qt's licence texts (from the `Licenses` folder of the Qt
installation) to the package.
