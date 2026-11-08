# Trainingsplaner Gewichtheben

Weekly training planning for weightlifting, as a replacement for the old
WinWoTA XP 2.61 program (IAT Leipzig / BVDG, 2009). It reads the old data,
uses the same exercise numbers, entry format and figures (WH, MHG, BW,
K1–K7), and prints the week plan in the familiar layout.

Built with Qt 6 (C++ and QML); data lives in a single SQLite file.

> This is an independent project. It is not affiliated with, endorsed by or
> derived from the code of IAT Leipzig, the BVDG or the WinWoTA program. Those
> names appear only to describe which program and data format this replaces.

## Features (version 0.1)

- **Wochenplan**: 7 days × 2 (optionally 3) sessions per athlete, plan or
  actual ("Ist"), week note and injured flag, K1–K7 weekly summary,
  copy/paste a whole week (also to another athlete).
- **Session editor**: weight exercises (kg, reps per set "SG", sets "ANZ",
  failed attempts "UG" in actual weeks), general exercises as text with total
  reps, free text lines, times and a note. Live MHG/BW/WH/SG-ANZ for the
  session and the whole week.
- **Sportler**: add, edit, delete athletes.
- **Import** of the old program's data export (`winwotaxp.bak`). Rows are
  merged by key and timestamp, so importing again is safe.
- **Print / PDF** of the week plan.

Not yet carried over: analysis and charts, macrocycles (MAZ), competitions,
individual training plans (ITP). The old database had no data in these.

## Moving the data from the old PC

1. On the old PC, use WinWoTA's data export ("Datenexport", option
   *komplett*) to write a current `winwotaxp.bak`.
2. In the new program: **Daten importieren…** and pick that file.

The exercise names are built into the new program; the old database only
had the numbers.

## Building

Requires Qt 6.5 or newer with the modules Quick, QuickControls2, Sql
(SQLite driver), PrintSupport and Widgets, plus CMake 3.21+.

```bash
qt-cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build
```

### Windows

1. Install Qt 6 with the online installer (component *MinGW 64-bit* and the
   matching MinGW toolchain), which includes Qt Creator.
2. Open `CMakeLists.txt` in Qt Creator, choose the *Release* configuration,
   build.
3. Make the program folder self-contained:

   In a *Qt 6 (MinGW)* command prompt, from the project folder (adjust the
   path to the build folder Qt Creator created):

   ```bat
   mkdir deploy
   copy <build folder>\trainingsplaner.exe deploy\
   windeployqt --qmldir qml deploy\trainingsplaner.exe
   ```

   Copy the `deploy` folder to the target PC; no installation or
   registration needed.

The database is stored at
`%APPDATA%\Trainingsplaner\Trainingsplaner\trainingsplaner.sqlite`
(shown under *Einstellungen*). To back up, close the program and copy that
file.

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

MIT, see [LICENSE](LICENSE).

The program uses [Qt](https://www.qt.io/) under the LGPL v3. When handing
out a Windows build made with `windeployqt`, Qt stays in separate DLLs as the
LGPL requires; add Qt's licence texts (from the `Licenses` folder of the Qt
installation) to the package.
