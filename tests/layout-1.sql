-- The database layout 1, as Trainingsplaner 0.3.0 and before created it
-- (src/database.cpp at v0.3.0). Tests build an old file from it to check
-- that sql/migrate-<n>.sql brings it up to date. Never change it.

CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS sp ( spid TEXT PRIMARY KEY, name TEXT NOT NULL DEFAULT '', vorname TEXT NOT NULL DEFAULT '', sex INTEGER NOT NULL DEFAULT 0, geb TEXT, adresse TEXT, telefon TEXT, user TEXT, korrektur TEXT);
CREATE TABLE IF NOT EXISTS te ( spid TEXT NOT NULL, wodate TEXT NOT NULL, tag INTEGER NOT NULL, te INTEGER NOT NULL, spi TEXT NOT NULL, art INTEGER DEFAULT 0, von TEXT, bis TEXT, bem TEXT, user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate, tag, te, spi));
CREATE TABLE IF NOT EXISTS te_ueb ( spid TEXT NOT NULL, wodate TEXT NOT NULL, tag INTEGER NOT NULL, te INTEGER NOT NULL, pos INTEGER NOT NULL, spi TEXT NOT NULL, ueb INTEGER DEFAULT 0, lststbem TEXT, art INTEGER DEFAULT 0, kombi INTEGER DEFAULT 0, user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate, tag, te, pos, spi));
CREATE TABLE IF NOT EXISTS wo ( spid TEXT NOT NULL, wodate TEXT NOT NULL, bel INTEGER, wklg TEXT, verletzt INTEGER, bem_soll TEXT, bem_plan TEXT, bem_ist TEXT, user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate));
CREATE TABLE IF NOT EXISTS normen ( sex INTEGER NOT NULL, akl INTEGER NOT NULL, gkl INTEGER NOT NULL, gklbez TEXT, zk INTEGER, user TEXT, korrektur TEXT, PRIMARY KEY (sex, akl, gkl));
CREATE TABLE IF NOT EXISTS spinfo ( spid TEXT NOT NULL, art TEXT NOT NULL, von TEXT NOT NULL, zeit TEXT NOT NULL DEFAULT '00:00:00', bis TEXT, info_text TEXT, info_zahl REAL, user TEXT, korrektur TEXT, PRIMARY KEY (spid, art, von, zeit));
CREATE TABLE IF NOT EXISTS wk ( spid TEXT NOT NULL, datum TEXT NOT NULL, zeit TEXT NOT NULL DEFAULT '00:00:00', wkart INTEGER, wk TEXT, ort TEXT, gew REAL, rei1 INTEGER, rei2 INTEGER, rei3 INTEGER, sto1 INTEGER, sto2 INTEGER, sto3 INTEGER, zk INTEGER, bem TEXT, user TEXT, korrektur TEXT, PRIMARY KEY (spid, datum, zeit));
CREATE TABLE IF NOT EXISTS maz ( id TEXT PRIMARY KEY, sex INTEGER DEFAULT 0, bez TEXT, kbez TEXT, von TEXT, bis TEXT, abp_von TEXT, lap_von TEXT, bem TEXT, user TEXT, korrektur TEXT);
CREATE TABLE IF NOT EXISTS maz_sp ( mazid TEXT NOT NULL, spid TEXT NOT NULL, gew INTEGER, ziel_rei INTEGER, ziel_sto INTEGER, wk_rei INTEGER, wk_sto INTEGER, auswahl TEXT DEFAULT 'Y', bem TEXT, user TEXT, korrektur TEXT, PRIMARY KEY (mazid, spid));
CREATE TABLE IF NOT EXISTS ueb ( spid TEXT NOT NULL, wodate TEXT NOT NULL, ueb INTEGER NOT NULL, spi TEXT NOT NULL DEFAULT 'S', wh INTEGER, mhg INTEGER, bw INTEGER, bwsg INTEGER, bwsganz INTEGER, user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate, ueb, spi));
CREATE TABLE IF NOT EXISTS itp_ls ( spid TEXT NOT NULL, wodate TEXT NOT NULL, ueb INTEGER NOT NULL, lststbem TEXT, user TEXT, korrektur TEXT, PRIMARY KEY (spid, wodate, ueb));
CREATE TABLE IF NOT EXISTS geloescht ( tabelle TEXT NOT NULL, schluessel TEXT NOT NULL, korrektur TEXT, PRIMARY KEY (tabelle, schluessel));
INSERT INTO meta (key, value) VALUES ('schema', '1');
