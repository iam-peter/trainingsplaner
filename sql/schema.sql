-- The Trainingsplaner database, from scratch:
--
--     sqlite3 trainingsplaner.sqlite < sql/schema.sql
--
-- The program runs this file on every start: tables that are missing are
-- created, existing ones stay as they are. A file of an older layout is
-- then brought up to date by sql/migrate-<n>.sql.
--
-- Dates are ISO text ("2026-11-09"), times of day "15:30:00". Every table
-- has changed_at, the row's last change ("2026-11-09 15:30:00"), which the
-- import compares to decide whether an incoming row is newer, and
-- changed_by. The old program's data files name tables and columns in
-- German (sp, te, wodate, ...); src/tables.cpp maps them to these.
--
-- Codes stored in columns keep the old program's letters: variant is
-- P (plan), I (actual, "Ist") or S (target, "Soll"). An owner is an
-- athlete's id, or '#' and a macrocycle's id for its framework plan.

-- Which layout the file has; the program refuses a file of a newer one
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);
INSERT OR IGNORE INTO meta (key, value) VALUES ('schema', '3');

-- sex 0 male, 1 female
CREATE TABLE IF NOT EXISTS athletes (
    id TEXT PRIMARY KEY,
    last_name TEXT NOT NULL DEFAULT '',
    first_name TEXT NOT NULL DEFAULT '',
    sex INTEGER NOT NULL DEFAULT 0,
    born TEXT,
    address TEXT,
    phone TEXT,
    changed_by TEXT,
    changed_at TEXT
);

-- Training sessions: monday is the week's, day 1-7 the weekday, number
-- the 1st to 3rd session of the day; start_time and end_time NULL when
-- not given
CREATE TABLE IF NOT EXISTS sessions (
    athlete_id TEXT NOT NULL,
    monday TEXT NOT NULL,
    day INTEGER NOT NULL,
    number INTEGER NOT NULL,
    variant TEXT NOT NULL,
    kind INTEGER DEFAULT 0,
    start_time TEXT,
    end_time TEXT,
    note TEXT,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (athlete_id, monday, day, number, variant)
);

-- The lines of a session in order; content holds the weight steps or
-- the text, encoded as the old program did (see Entry::encode); kind
-- 0 weights, 1 exercise as text, 2 free text
CREATE TABLE IF NOT EXISTS session_entries (
    athlete_id TEXT NOT NULL,
    monday TEXT NOT NULL,
    day INTEGER NOT NULL,
    number INTEGER NOT NULL,
    position INTEGER NOT NULL,
    variant TEXT NOT NULL,
    exercise INTEGER DEFAULT 0,
    content TEXT,
    kind INTEGER DEFAULT 0,
    combination INTEGER DEFAULT 0,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (athlete_id, monday, day, number, position, variant)
);

-- Per week of an owner: the athlete's notes on plan and actual training,
-- and the framework plan's load and competition position with its note
CREATE TABLE IF NOT EXISTS weeks (
    owner TEXT NOT NULL,
    monday TEXT NOT NULL,
    load INTEGER,
    competition_position TEXT,
    injured INTEGER,
    target_note TEXT,
    plan_note TEXT,
    actual_note TEXT,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (owner, monday)
);

-- Reference totals by sex, age class and weight class (from the old
-- program); a weight class named with a + has no upper limit
CREATE TABLE IF NOT EXISTS reference_totals (
    sex INTEGER NOT NULL,
    age_class INTEGER NOT NULL,
    weight_class INTEGER NOT NULL,
    weight_class_name TEXT,
    total INTEGER,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (sex, age_class, weight_class)
);

-- Athlete attributes valid from_date to to_date (kind Kader, Verein, ...;
-- the value in text) and extra info per day (kind KG, KF, ...; the value
-- in number at from_date and time); time 00:00:00 when not given, as it
-- is part of the key
CREATE TABLE IF NOT EXISTS athlete_info (
    athlete_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    from_date TEXT NOT NULL,
    time TEXT NOT NULL DEFAULT '00:00:00',
    to_date TEXT,
    text TEXT,
    number REAL,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (athlete_id, kind, from_date, time)
);

-- Competition results; an attempt is the weight, negative when invalid,
-- NULL when not taken; time 00:00:00 when not given
CREATE TABLE IF NOT EXISTS competitions (
    athlete_id TEXT NOT NULL,
    date TEXT NOT NULL,
    time TEXT NOT NULL DEFAULT '00:00:00',
    type INTEGER,
    name TEXT,
    place TEXT,
    body_weight REAL,
    snatch1 INTEGER,
    snatch2 INTEGER,
    snatch3 INTEGER,
    clean_jerk1 INTEGER,
    clean_jerk2 INTEGER,
    clean_jerk3 INTEGER,
    total INTEGER,
    note TEXT,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (athlete_id, date, time)
);

-- Macrocycles (MAZ), from the first to the last week, with the Mondays
-- their build-up and peak phases begin
CREATE TABLE IF NOT EXISTS macrocycles (
    id TEXT PRIMARY KEY,
    sex INTEGER DEFAULT 0,
    name TEXT,
    short_name TEXT,
    first_monday TEXT,
    last_monday TEXT,
    build_up_monday TEXT,
    peak_monday TEXT,
    note TEXT,
    changed_by TEXT,
    changed_at TEXT
);

-- The athletes of a macrocycle with their targets and results; selected
-- 1 or 0
CREATE TABLE IF NOT EXISTS macrocycle_athletes (
    macrocycle_id TEXT NOT NULL,
    athlete_id TEXT NOT NULL,
    weight_class INTEGER,
    target_snatch INTEGER,
    target_clean_jerk INTEGER,
    competition_snatch INTEGER,
    competition_clean_jerk INTEGER,
    selected INTEGER NOT NULL DEFAULT 1,
    note TEXT,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (macrocycle_id, athlete_id)
);

-- Week targets per exercise of an owner (the athlete's ITP or the
-- framework plan); exercise -1..-7 stands for the groups K1..K7. reps:
-- repetitions (WH), mean_weight (MHG), top_weight (BW) with its reps and
-- sets
CREATE TABLE IF NOT EXISTS week_targets (
    owner TEXT NOT NULL,
    monday TEXT NOT NULL,
    exercise INTEGER NOT NULL,
    variant TEXT NOT NULL DEFAULT 'S',
    reps INTEGER,
    mean_weight INTEGER,
    top_weight INTEGER,
    top_weight_reps INTEGER,
    top_weight_sets INTEGER,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (owner, monday, exercise, variant)
);

-- Planned weight steps per week and exercise of an owner, encoded as in
-- session_entries (new in this program)
CREATE TABLE IF NOT EXISTS planned_steps (
    owner TEXT NOT NULL,
    monday TEXT NOT NULL,
    exercise INTEGER NOT NULL,
    steps TEXT,
    changed_by TEXT,
    changed_at TEXT,
    PRIMARY KEY (owner, monday, exercise)
);

-- Deleted rows, so an export of changes can pass deletions on; row_key
-- is the row's key, its parts joined by U+001F
CREATE TABLE IF NOT EXISTS deletions (
    table_name TEXT NOT NULL,
    row_key TEXT NOT NULL,
    deleted_at TEXT,
    PRIMARY KEY (table_name, row_key)
);
