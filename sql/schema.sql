-- The Trainingsplaner database, from scratch:
--
--     sqlite3 trainingsplaner.sqlite < sql/schema.sql
--
-- The program runs this file on every start: tables that are missing are
-- created, existing ones stay as they are. A file of an older layout is
-- then brought up to date by sql/migrate-<n>.sql.
--
-- The tables and columns follow the old program's database, so imported
-- data maps one to one. Dates are ISO text ("2026-11-09"), times of day
-- "15:30:00", and `korrektur` is every row's last change
-- ("2026-11-09 15:30:00"); the importer compares it to decide whether an
-- incoming row is newer.

-- Which layout the file has; the program refuses a file of a newer one
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);
INSERT OR IGNORE INTO meta (key, value) VALUES ('schema', '2');

-- Athletes ("Sportler"); sex 0 male, 1 female
CREATE TABLE IF NOT EXISTS sp (
    spid TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    vorname TEXT NOT NULL DEFAULT '',
    sex INTEGER NOT NULL DEFAULT 0,
    geb TEXT,
    adresse TEXT,
    telefon TEXT,
    user TEXT,
    korrektur TEXT
);

-- Training sessions ("Trainingseinheiten"): wodate is the Monday of the
-- week, tag 1-7 the weekday, te the session number, spi P (plan) or
-- I (actual); von/bis NULL when no time is given
CREATE TABLE IF NOT EXISTS te (
    spid TEXT NOT NULL,
    wodate TEXT NOT NULL,
    tag INTEGER NOT NULL,
    te INTEGER NOT NULL,
    spi TEXT NOT NULL,
    art INTEGER DEFAULT 0,
    von TEXT,
    bis TEXT,
    bem TEXT,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, wodate, tag, te, spi)
);

-- Lines of a session; lststbem holds the encoded content (see
-- Entry::encode)
CREATE TABLE IF NOT EXISTS te_ueb (
    spid TEXT NOT NULL,
    wodate TEXT NOT NULL,
    tag INTEGER NOT NULL,
    te INTEGER NOT NULL,
    pos INTEGER NOT NULL,
    spi TEXT NOT NULL,
    ueb INTEGER DEFAULT 0,
    lststbem TEXT,
    art INTEGER DEFAULT 0,
    kombi INTEGER DEFAULT 0,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, wodate, tag, te, pos, spi)
);

-- Week notes
CREATE TABLE IF NOT EXISTS wo (
    spid TEXT NOT NULL,
    wodate TEXT NOT NULL,
    bel INTEGER,
    wklg TEXT,
    verletzt INTEGER,
    bem_soll TEXT,
    bem_plan TEXT,
    bem_ist TEXT,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, wodate)
);

-- Reference totals by sex, age class and weight class (from the old
-- program)
CREATE TABLE IF NOT EXISTS normen (
    sex INTEGER NOT NULL,
    akl INTEGER NOT NULL,
    gkl INTEGER NOT NULL,
    gklbez TEXT,
    zk INTEGER,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (sex, akl, gkl)
);

-- Athlete attributes with a time range (art = Kader, Verein, ...) and
-- extra info per day (art = KG, KF, ...: info_zahl at von/zeit); zeit
-- 00:00:00 when no time is given, as it is part of the key
CREATE TABLE IF NOT EXISTS spinfo (
    spid TEXT NOT NULL,
    art TEXT NOT NULL,
    von TEXT NOT NULL,
    zeit TEXT NOT NULL DEFAULT '00:00:00',
    bis TEXT,
    info_text TEXT,
    info_zahl REAL,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, art, von, zeit)
);

-- Competitions; a negative attempt was invalid at that weight
CREATE TABLE IF NOT EXISTS wk (
    spid TEXT NOT NULL,
    datum TEXT NOT NULL,
    zeit TEXT NOT NULL DEFAULT '00:00:00',
    wkart INTEGER,
    wk TEXT,
    ort TEXT,
    gew REAL,
    rei1 INTEGER,
    rei2 INTEGER,
    rei3 INTEGER,
    sto1 INTEGER,
    sto2 INTEGER,
    sto3 INTEGER,
    zk INTEGER,
    bem TEXT,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, datum, zeit)
);

-- Macrocycles (MAZ); von/bis/abp_von/lap_von are Mondays
CREATE TABLE IF NOT EXISTS maz (
    id TEXT PRIMARY KEY,
    sex INTEGER DEFAULT 0,
    bez TEXT,
    kbez TEXT,
    von TEXT,
    bis TEXT,
    abp_von TEXT,
    lap_von TEXT,
    bem TEXT,
    user TEXT,
    korrektur TEXT
);

-- The athletes of a MAZ; auswahl 1 selected, 0 not
CREATE TABLE IF NOT EXISTS maz_sp (
    mazid TEXT NOT NULL,
    spid TEXT NOT NULL,
    gew INTEGER,
    ziel_rei INTEGER,
    ziel_sto INTEGER,
    wk_rei INTEGER,
    wk_sto INTEGER,
    auswahl INTEGER NOT NULL DEFAULT 1,
    bem TEXT,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (mazid, spid)
);

-- Week targets per exercise: ITP (spid = athlete) or framework plan
-- (spid = '#' + MAZ id); ueb -1..-7 stand for the groups K1..K7
CREATE TABLE IF NOT EXISTS ueb (
    spid TEXT NOT NULL,
    wodate TEXT NOT NULL,
    ueb INTEGER NOT NULL,
    spi TEXT NOT NULL DEFAULT 'S',
    wh INTEGER,
    mhg INTEGER,
    bw INTEGER,
    bwsg INTEGER,
    bwsganz INTEGER,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, wodate, ueb, spi)
);

-- Planned weight steps per week and exercise (new in this program)
CREATE TABLE IF NOT EXISTS itp_ls (
    spid TEXT NOT NULL,
    wodate TEXT NOT NULL,
    ueb INTEGER NOT NULL,
    lststbem TEXT,
    user TEXT,
    korrektur TEXT,
    PRIMARY KEY (spid, wodate, ueb)
);

-- Deleted rows, so an export of changes can pass deletions on;
-- schluessel is the row's key, its parts joined by U+001F
CREATE TABLE IF NOT EXISTS geloescht (
    tabelle TEXT NOT NULL,
    schluessel TEXT NOT NULL,
    korrektur TEXT,
    PRIMARY KEY (tabelle, schluessel)
);
