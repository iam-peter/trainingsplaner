# Roadmap

What comes after version 0.2.0. Based on a look at coaching software for
weightlifting (CoachLogik, TeamBuildr, TrainHeroic, Strength Academy and
competition calculators) and on a review of our own user interface.

## Phase 0 – Verify against the old program (first)

Everything below builds on correct numbers. WH, MHG and BW per exercise
line, the week's figures per exercise, K1–K7 and K1-7/K1-5 with tonnage
agree with 75 week plans printed by WinWoTA (the sample plans of the BVDG's
Rahmentrainingskonzeption 2019, `tests/fixtures/`, checked by `tst_core`). Which
target a framework plan percentage refers to follows the same document. The
analyses, the rounding and the complexes in the conversion from framework
plan to ITP, the competition chart with the reference total and the group
percentages are not yet compared with WinWoTA XP.

1. Work through the test protocol on the old PC (test athlete, four weeks,
   competitions, MAZ with framework plan and ITP; screenshots of every
   report; complete data export).
2. Import the export, run the same evaluations, fix every difference.
3. Turn the old program's results into automated tests.
4. Remove the "not yet verified" note from the release text.

## Phase 1 – User interface quick wins

No new data, every user benefits at once.

- [x] **Colours that work in dark mode.** The day cells are hard-coded pale
      yellow and glare in a dark window. Use palette-aware colours, and mark
      today.
- [x] **Compact week grid.** Hide an empty 1st-session row, rows sized to
      their content, a small header naming the columns (TÜ WH MHG BW SG/ANZ),
      exercise names on hover.
- [x] **One athlete selection** shared by week plan, planning, analyses and
      competitions.
- [x] **Keyboard shortcuts:** Ctrl+←/→ weeks, Ctrl+P print, Ctrl+S save,
      Enter open, Delete remove, Ctrl+Z / Ctrl+Y.
- [x] **Context menu** on sessions and lines: copy, paste, delete,
      "Ist = Plan".
- [x] **Undo / redo** for saving, deleting and pasting.
- [x] **Charts:** values on hover, save as image.
- [x] **Help:** tooltips for WH, MHG, BW, SG/ANZ, UG, K1–K7; a short help
      page; a first-start dialog (import old data or try demo data, trainer
      name).
- [x] **Analyses at once:** reports without a button to press, following
      their settings; tables like the old program's reports, copied for a
      spreadsheet or saved as CSV.
- [x] **Paper and orientation** for the week plan: A4, A5 or A3, portrait
      or landscape.

The coach's wishes come next, in small steps close to WinWoTA (details
and order in [UX-PLAN.md](UX-PLAN.md)):

- [ ] **Sessions per day** as a setting (1–3) instead of the "3 TE" box.
- [ ] **The previous week** beside each exercise in the session editor
      and in the K1–K7 summary; optionally the whole previous week above
      the current one.
- [ ] **A movable, non-modal session editor.**
- [ ] **A month view** with the sessions and the competition dates, for
      one athlete or all, printable.
- [ ] **The load chart** (Ist against Ziel per week, the sawtooth of
      raised and lowered weeks), after asking the coach what it shows.
- [ ] **Youth competitions** of the DGJ: types, one per week, DM norms.
- [ ] Later, if wanted: one sidebar instead of two tab bars
      ([NAVIGATION.md](NAVIGATION.md)).

## Phase 2 – Weightlifting planning

- [ ] **Maxes per athlete and exercise**, with history. Updated from
      competitions and from new best weights in training; a notice when a
      training best beats the stored max.
- [ ] **Plan in percent:** `80%/3/2` becomes kg from the athlete's max,
      rounded to the weight step; every kg shows its percent.
- [ ] **Quick actual entry:** take over the planned week as actual with one
      click and change only what differed; feeling (RPE 1–10) and a note per
      session.
- [ ] **Complexes** such as clean + 2 jerks (`1+2`), using the combination
      field the old data format already has.
- [ ] **Intensity zones** (< 70, 70–80, 80–90, > 90 % of max) per week and
      cycle, average relative intensity and K-value (average intensity /
      competition total) in the weekly summary and the analyses.

## Phase 3 – Groups and competitions

- [ ] **Group view:** one week for all athletes of a MAZ or Kader; give one
      week's plan to several athletes at once.
- [ ] **Templates:** save a week or block without dates; apply it to any
      athlete, scaled to their maxes.
- [ ] **Competition planner:** openers and jumps for snatch and clean & jerk
      from the recent bests, weigh-in and weight class, a printable
      competition-day sheet with plate loading.
- [ ] **Body weight chart** from the extra info, against the weight class.
- [ ] **Print preview** inside the program; print a whole group's plans.

## Phase 4 – Plans on the athletes' phones (separate decision)

Athletes see their plan on their phone and enter what they actually did,
with no cloud service: the data stays on the coach's PC.

### Recommended: a small web server inside the program

The program can serve a mobile web page in the local network (Wi-Fi in the
gym or at home). No app to install, works on any phone with a browser.

- **Turning it on:** Settings › "Für Sportler freigeben". The program then
  listens on the local network only (for example port 8470). Windows asks
  once whether to allow it in the firewall.
- **One link per athlete:** each athlete gets a personal link with a random
  key, shown as a QR code to scan once (for example
  `http://192.168.1.20:8470/s/k3F9…`). The key can be renewed at any time,
  which makes the old link useless. An athlete sees only their own weeks.
- **What athletes see:** today's and the week's sessions, large and
  readable, weights with plate loading; earlier weeks.
- **What athletes enter:** per exercise "as planned" with one tap or the
  actual weights, reps, sets and failed attempts; feeling and a note. The
  entries land in the "Ist" week in the program, marked as entered by the
  athlete, and the coach sees them at once.
- **Gym tablet mode:** one link for the whole group that lists today's
  sessions of all athletes, for a tablet in the weight room.
- **Building blocks:** Qt HTTP Server (part of Qt) for the server, a single
  self-contained HTML page with no outside scripts or fonts, the existing
  Store and database functions for reading and writing.

**Limits, to say openly:**

- The coach's PC has to be on and in the same network. On the move, the
  athletes see nothing new.
- The connection is plain HTTP inside the local network; anyone in the same
  network who had a link could read along. Acceptable for a club Wi-Fi with
  personal keys, not for public Wi-Fi.
- Older phones cannot install the page as an app (that needs HTTPS), but
  the browser bookmark works everywhere.

### Fallback without a shared network

For when the PC and the athletes are not in one network:

- **Plan as a file:** a self-contained HTML page (or PDF) per athlete and
  week, sent by messenger or e-mail. Opens offline on any phone.
- **Results back as a code:** that page has input fields; "Senden" puts the
  entries into a short text block (or QR code) that the athlete sends back.
  The coach pastes it into the program ("Daten › Sportler-Ergebnisse
  einlesen"), which checks the athlete and week and fills the "Ist" week.

Clumsier than the server, but it works anywhere and needs no setup.

### Not recommended (for now)

- **A native phone app** (Qt for Android/iOS from the same code): better
  experience, but app store distribution, especially on iPhones, is a large
  effort for a club tool.
- **A synced folder** (Syncthing, Nextcloud, OneDrive): still needs an app
  on the phone and gives conflicts when two sides edit at once.
- **Any cloud service:** against the goal that the data stays local.

### Before building it

- Decide whether athletes may change planned weeks or only enter actuals
  (recommended: actuals only).
- Decide how long links stay valid and whether the server starts with the
  program or by hand.
- Data protection: athletes' training data then leaves the coach's PC (to
  their own phones). Tell the athletes, and keep the keys secret.
