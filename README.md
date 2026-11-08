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
| `trainingsplaner-windows-x64.zip` | Windows 10/11: unzip, start `trainingsplaner.exe` |
| `trainingsplaner-macos.dmg` | macOS, Apple silicon and Intel |
| `trainingsplaner-linux-x64.AppImage` | any Linux |
| `trainingsplaner-linux-x64.deb` | Debian and Ubuntu, with its own Qt |

The programs aren't signed: Windows SmartScreen asks once (*Weitere
Informationen*, *Trotzdem ausführen*), on macOS open the app with a right
click and *Öffnen* the first time.

## Features (version 0.1)

- **Wochenplan**: 7 days × 2 (optionally 3) sessions per athlete, plan or
  actual ("Ist"), week note and injured flag, K1–K7 weekly summary,
  copy/paste a whole week (also to another athlete).
- **Session editor**: weight exercises (kg, reps per set "SG", sets "ANZ",
  failed attempts "UG" in actual weeks), general exercises as text with total
  reps, free text lines, times and a note. Live MHG/BW/WH/SG-ANZ for the
  session and the whole week.
- **Sportler**: add, edit, delete athletes.
- **Import** of data exports from WinWoTA XP (see below).
- **Print / PDF** of the week plan.

Planned: analysis and charts, macrocycles, competitions, individual
training plans.

## Data from WinWoTA XP

Users of the older WinWoTA XP 2.61 can bring their data along: export it
there ("Datenexport", option *komplett*, gives `winwotaxp.bak`), then use
**Daten importieren…** here. The exercise numbers are the same. Rows are
merged by key and timestamp, so importing again is safe.

This is an independent project. It is not affiliated with, endorsed by or
derived from the code of IAT Leipzig, the BVDG or WinWoTA; the names only
describe which program and data format can be imported.

## Building

Requires Qt 6.5 or newer with the modules Quick, QuickControls2, Sql
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
| **Nightly** | every night with new commits (or by hand): builds and tests on Linux, Windows and macOS and replaces the `nightly` pre-release |
| **Promote Release** | run by hand with a version such as `0.2.0`: publishes the current nightly's files as release `v0.2.0` |
| **Website** | publishes `pages/` on GitHub Pages; the page finds the newest release and nightly by itself |

To release: bump `project(... VERSION ...)` in `CMakeLists.txt`, wait for
(or start) the nightly, then run *Promote Release*.

## Command line

| Option | Purpose |
|---|---|
| `--db <file>` | use another database file |
| `--import <file.bak>` | import an old data export and exit |
| `--athlete <id> --week 46/2026 --open 1:2 --page sportler` | start at a given place |
| `--grab <file.png>` | save a screenshot and exit (for testing) |

## Code layout

| Path | Content |
|---|---|
| `src/catalog.*` | exercise catalogue (numbers, groups, names) |
| `src/steps.*` | weight step encoding and the load figures |
| `src/model.h` | athletes, sessions, entries, weeks, weekly summary |
| `src/database.*` | SQLite storage |
| `src/bakimport.*` | importer for the old program's export |
| `src/weekreport.*` | printed / PDF week plan |
| `src/store.*` | API for the QML user interface |
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
