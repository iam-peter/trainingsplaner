# Navigation concept

A proposal, not built yet. It replaces the two stacked tab bars (the main
areas, and under three of them a second bar of sub-tabs) with one sidebar.

## Why the tabs fall short

- Both levels look the same (a bar of pills above a bar of pills), so the
  sub-tabs read as a second main navigation instead of a part of the area.
- Half the program sits on the second level: Planung has three sub-tabs
  (MAZ, ITP / RO, Laststufen), Analyse four (Individualanalyse,
  Gruppenanalyse, Datenprüfung, Grafik), Wettkämpfe two (Ergebnisse,
  Grafik).
- Every page shows its own athlete box. The selection itself is already
  shared (`window.athlete` in `Main.qml` is bound to every page), but
  nothing shows that it is one selection.

## What other programs do

- **Sidebar with sections**: Outlook, Teams, Linear, Notion, the system
  settings of Windows and macOS, training software such as TrainingPeaks.
  The usual answer for ten to fifteen views.
- **Context picker above the navigation**: Slack's workspace, the property
  in Google Analytics. What you work on is chosen apart from where you are.
- **Tree of objects**: file managers, IDEs, Lightroom. Fits when the
  objects are what one moves between.

## Options considered

- **A – Sidebar with sections, the selection as pickers in it.** Chosen.
- **B – Tree of athletes and MAZ with their views as children.** Needs a
  rule for switching (another athlete keeps the view), the group views fit
  no athlete, and the tree grows with every athlete.
- **C – Keep the main bar, sub-views as underlined tabs in the page's own
  toolbar.** The smallest change; it separates the two levels visually but
  keeps an athlete box on every page.

## The sidebar

Views depend on one of two subjects, an athlete or a MAZ (a group of
athletes in one cycle), or on all athletes. The sidebar has a section for
each, and a section's picker is its header:

```
Sportler   [ Carvalho, Mikhail  v ]
  Wochenplan
  ITP                 (Laststufen as a switch in its toolbar)
  Wettkämpfe          (Ergebnisse and Grafik in the page)
  Analyse             (Individualanalyse and the athlete's Grafik)

MAZ        [ TMZ – Test MZ      v ]
  Übersicht           (dates, phases, athletes with their targets)
  Rahmenorientierung  (Laststufen as a switch in its toolbar)
  Gruppenanalyse

Allgemein
  Sportler verwalten
  Datenprüfung        (all selectable athletes)

Daten · Einstellungen · Hilfe   (at the foot)
```

Laststufen belongs to whoever owns the plan (an athlete's ITP or a MAZ's
Rahmenorientierung), which today the ITP / RO switch decides. It moves into
those two views instead of being an entry of its own.

## Rules

- A picker changes only its section's selection, never the view.
- An entry changes only the view, never a selection.
- Both selections stay while one moves between sections: from Mira's
  Wochenplan to the MAZ overview and back, Mira is still selected.
- Moving between the subjects is an explicit link, never a side effect:
  in the MAZ overview every athlete's row has "ITP öffnen", which selects
  the athlete and opens the ITP; an athlete's ITP names its MAZ with a link
  to the MAZ overview.
- A view without the subject it needs (no athlete yet, no MAZ yet) says so
  and offers to create one, as the pages do today.

## Where the subjects meet: the ITP

An athlete's ITP covers one of the athlete's MAZ, or a range of its own.
Taking the sidebar's MAZ would break for an athlete who is not in it, so
the ITP keeps its own period picker, limited to the athlete's MAZ as today.
It starts on the sidebar's MAZ when the athlete is in it; the sidebar's MAZ
is a default there, never a constraint.

## Alternative kept in mind: MAZ above the athlete

Pick a MAZ first and the athlete picker lists only its athletes, like a
workspace and its channels. Fits coaches who always work within one cycle,
but athletes without a MAZ or in several need an "Alle Sportler"
pseudo-group, and the week plan would depend on a MAZ for no reason. Two
pickers side by side avoid both.

## What changes in the code

- `Main.qml`: the main tab bar and the toolbar buttons give way to the
  sidebar; Daten, Einstellungen and Hilfe move to its foot.
- The pages lose their sub-tab bars and their own athlete boxes; the
  sidebar's two selections are bound to them as `window.athlete` is today.
  The MAZ selection becomes a second shared selection (`window.maz`).
- Planung splits into its athlete part (ITP, Laststufen) and its MAZ part
  (MAZ, Rahmenorientierung, Laststufen); Analyse and Wettkämpfe lose their
  tabs.

## Open questions

- Width: at the smallest window (1000 px) a 200 px sidebar takes room from
  the ITP grid and the week plan. It should collapse to a strip of icons
  (about 56 px), by itself below some window width and on request.
- The Grafik compares with a second athlete; that picker stays in the page.
- Whether "Sportler verwalten" stays under Allgemein or becomes the
  athlete picker's own "Bearbeiten" entry.
