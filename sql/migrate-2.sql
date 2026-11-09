-- Layout 1 (Trainingsplaner up to 0.3.0) to layout 2. The program runs
-- it in one transaction, after keeping a copy of the file; by hand, on a
-- copy, all or nothing:
--
--     sqlite3 -bail trainingsplaner.sqlite "BEGIN" ".read sql/migrate-2.sql" "COMMIT"
--
-- The tables are written out as they are in layout 2, not taken from
-- schema.sql, so this step stays the same when the layout changes again.

-- maz_sp.auswahl: 1 or 0 instead of 'Y' or 'N'. SQLite cannot change a
-- column's type, so the table is built anew.
ALTER TABLE maz_sp RENAME TO maz_sp_v1;
CREATE TABLE maz_sp (
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
INSERT INTO maz_sp (mazid, spid, gew, ziel_rei, ziel_sto, wk_rei, wk_sto, auswahl, bem, user, korrektur)
    SELECT mazid, spid, gew, ziel_rei, ziel_sto, wk_rei, wk_sto,
           CASE WHEN upper(trim(coalesce(auswahl, ''))) IN ('N', '0') THEN 0 ELSE 1 END,
           bem, user, korrektur
    FROM maz_sp_v1;
DROP TABLE maz_sp_v1;

-- Sessions: one form of "no time" (NULL) and of a time (15:30:00)
UPDATE te SET von = NULL WHERE trim(von) IN ('', '00:00:00');
UPDATE te SET bis = NULL WHERE trim(bis) IN ('', '00:00:00');
UPDATE te SET von = strftime('%H:%M:%S', von) WHERE strftime('%H:%M:%S', von) IS NOT NULL;
UPDATE te SET bis = strftime('%H:%M:%S', bis) WHERE strftime('%H:%M:%S', bis) IS NOT NULL;

-- Change stamps in one form; imports kept them as the file had them,
-- e.g. with a T between date and time
UPDATE sp SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE te SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE te_ueb SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE wo SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE normen SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE spinfo SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE wk SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE maz SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE maz_sp SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE ueb SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE itp_ls SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;
UPDATE geloescht SET korrektur = strftime('%Y-%m-%d %H:%M:%S', korrektur) WHERE strftime('%Y-%m-%d %H:%M:%S', korrektur) IS NOT NULL;

UPDATE meta SET value = '2' WHERE key = 'schema';
