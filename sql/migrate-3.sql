-- Layout 2 to layout 3: English names for every table and column. The
-- old program's names stay where its data files need them, in
-- src/tables.cpp. The program runs this in one transaction, after
-- keeping a copy of the file; by hand, on a copy, all or nothing:
--
--     sqlite3 -bail trainingsplaner.sqlite "BEGIN" ".read sql/migrate-3.sql" "COMMIT"
--
-- Renaming keeps every row, key and value as it is.

-- sp -> athletes
ALTER TABLE sp RENAME COLUMN spid TO id;
ALTER TABLE sp RENAME COLUMN name TO last_name;
ALTER TABLE sp RENAME COLUMN vorname TO first_name;
ALTER TABLE sp RENAME COLUMN geb TO born;
ALTER TABLE sp RENAME COLUMN adresse TO address;
ALTER TABLE sp RENAME COLUMN telefon TO phone;
ALTER TABLE sp RENAME COLUMN user TO changed_by;
ALTER TABLE sp RENAME COLUMN korrektur TO changed_at;
ALTER TABLE sp RENAME TO athletes;

-- te -> sessions
ALTER TABLE te RENAME COLUMN spid TO athlete_id;
ALTER TABLE te RENAME COLUMN wodate TO monday;
ALTER TABLE te RENAME COLUMN tag TO day;
ALTER TABLE te RENAME COLUMN te TO number;
ALTER TABLE te RENAME COLUMN spi TO variant;
ALTER TABLE te RENAME COLUMN art TO kind;
ALTER TABLE te RENAME COLUMN von TO start_time;
ALTER TABLE te RENAME COLUMN bis TO end_time;
ALTER TABLE te RENAME COLUMN bem TO note;
ALTER TABLE te RENAME COLUMN user TO changed_by;
ALTER TABLE te RENAME COLUMN korrektur TO changed_at;
ALTER TABLE te RENAME TO sessions;

-- te_ueb -> session_entries
ALTER TABLE te_ueb RENAME COLUMN spid TO athlete_id;
ALTER TABLE te_ueb RENAME COLUMN wodate TO monday;
ALTER TABLE te_ueb RENAME COLUMN tag TO day;
ALTER TABLE te_ueb RENAME COLUMN te TO number;
ALTER TABLE te_ueb RENAME COLUMN pos TO position;
ALTER TABLE te_ueb RENAME COLUMN spi TO variant;
ALTER TABLE te_ueb RENAME COLUMN ueb TO exercise;
ALTER TABLE te_ueb RENAME COLUMN lststbem TO content;
ALTER TABLE te_ueb RENAME COLUMN art TO kind;
ALTER TABLE te_ueb RENAME COLUMN kombi TO combination;
ALTER TABLE te_ueb RENAME COLUMN user TO changed_by;
ALTER TABLE te_ueb RENAME COLUMN korrektur TO changed_at;
ALTER TABLE te_ueb RENAME TO session_entries;

-- wo -> weeks
ALTER TABLE wo RENAME COLUMN spid TO owner;
ALTER TABLE wo RENAME COLUMN wodate TO monday;
ALTER TABLE wo RENAME COLUMN bel TO load;
ALTER TABLE wo RENAME COLUMN wklg TO competition_position;
ALTER TABLE wo RENAME COLUMN verletzt TO injured;
ALTER TABLE wo RENAME COLUMN bem_soll TO target_note;
ALTER TABLE wo RENAME COLUMN bem_plan TO plan_note;
ALTER TABLE wo RENAME COLUMN bem_ist TO actual_note;
ALTER TABLE wo RENAME COLUMN user TO changed_by;
ALTER TABLE wo RENAME COLUMN korrektur TO changed_at;
ALTER TABLE wo RENAME TO weeks;

-- normen -> reference_totals
ALTER TABLE normen RENAME COLUMN akl TO age_class;
ALTER TABLE normen RENAME COLUMN gkl TO weight_class;
ALTER TABLE normen RENAME COLUMN gklbez TO weight_class_name;
ALTER TABLE normen RENAME COLUMN zk TO total;
ALTER TABLE normen RENAME COLUMN user TO changed_by;
ALTER TABLE normen RENAME COLUMN korrektur TO changed_at;
ALTER TABLE normen RENAME TO reference_totals;

-- spinfo -> athlete_info
ALTER TABLE spinfo RENAME COLUMN spid TO athlete_id;
ALTER TABLE spinfo RENAME COLUMN art TO kind;
ALTER TABLE spinfo RENAME COLUMN von TO from_date;
ALTER TABLE spinfo RENAME COLUMN zeit TO time;
ALTER TABLE spinfo RENAME COLUMN bis TO to_date;
ALTER TABLE spinfo RENAME COLUMN info_text TO text;
ALTER TABLE spinfo RENAME COLUMN info_zahl TO number;
ALTER TABLE spinfo RENAME COLUMN user TO changed_by;
ALTER TABLE spinfo RENAME COLUMN korrektur TO changed_at;
ALTER TABLE spinfo RENAME TO athlete_info;

-- wk -> competitions
ALTER TABLE wk RENAME COLUMN spid TO athlete_id;
ALTER TABLE wk RENAME COLUMN datum TO date;
ALTER TABLE wk RENAME COLUMN zeit TO time;
ALTER TABLE wk RENAME COLUMN wkart TO type;
ALTER TABLE wk RENAME COLUMN wk TO name;
ALTER TABLE wk RENAME COLUMN ort TO place;
ALTER TABLE wk RENAME COLUMN gew TO body_weight;
ALTER TABLE wk RENAME COLUMN rei1 TO snatch1;
ALTER TABLE wk RENAME COLUMN rei2 TO snatch2;
ALTER TABLE wk RENAME COLUMN rei3 TO snatch3;
ALTER TABLE wk RENAME COLUMN sto1 TO clean_jerk1;
ALTER TABLE wk RENAME COLUMN sto2 TO clean_jerk2;
ALTER TABLE wk RENAME COLUMN sto3 TO clean_jerk3;
ALTER TABLE wk RENAME COLUMN zk TO total;
ALTER TABLE wk RENAME COLUMN bem TO note;
ALTER TABLE wk RENAME COLUMN user TO changed_by;
ALTER TABLE wk RENAME COLUMN korrektur TO changed_at;
ALTER TABLE wk RENAME TO competitions;

-- maz -> macrocycles
ALTER TABLE maz RENAME COLUMN bez TO name;
ALTER TABLE maz RENAME COLUMN kbez TO short_name;
ALTER TABLE maz RENAME COLUMN von TO first_monday;
ALTER TABLE maz RENAME COLUMN bis TO last_monday;
ALTER TABLE maz RENAME COLUMN abp_von TO build_up_monday;
ALTER TABLE maz RENAME COLUMN lap_von TO peak_monday;
ALTER TABLE maz RENAME COLUMN bem TO note;
ALTER TABLE maz RENAME COLUMN user TO changed_by;
ALTER TABLE maz RENAME COLUMN korrektur TO changed_at;
ALTER TABLE maz RENAME TO macrocycles;

-- maz_sp -> macrocycle_athletes
ALTER TABLE maz_sp RENAME COLUMN mazid TO macrocycle_id;
ALTER TABLE maz_sp RENAME COLUMN spid TO athlete_id;
ALTER TABLE maz_sp RENAME COLUMN gew TO weight_class;
ALTER TABLE maz_sp RENAME COLUMN ziel_rei TO target_snatch;
ALTER TABLE maz_sp RENAME COLUMN ziel_sto TO target_clean_jerk;
ALTER TABLE maz_sp RENAME COLUMN wk_rei TO competition_snatch;
ALTER TABLE maz_sp RENAME COLUMN wk_sto TO competition_clean_jerk;
ALTER TABLE maz_sp RENAME COLUMN auswahl TO selected;
ALTER TABLE maz_sp RENAME COLUMN bem TO note;
ALTER TABLE maz_sp RENAME COLUMN user TO changed_by;
ALTER TABLE maz_sp RENAME COLUMN korrektur TO changed_at;
ALTER TABLE maz_sp RENAME TO macrocycle_athletes;

-- ueb -> week_targets
ALTER TABLE ueb RENAME COLUMN spid TO owner;
ALTER TABLE ueb RENAME COLUMN wodate TO monday;
ALTER TABLE ueb RENAME COLUMN ueb TO exercise;
ALTER TABLE ueb RENAME COLUMN spi TO variant;
ALTER TABLE ueb RENAME COLUMN wh TO reps;
ALTER TABLE ueb RENAME COLUMN mhg TO mean_weight;
ALTER TABLE ueb RENAME COLUMN bw TO top_weight;
ALTER TABLE ueb RENAME COLUMN bwsg TO top_weight_reps;
ALTER TABLE ueb RENAME COLUMN bwsganz TO top_weight_sets;
ALTER TABLE ueb RENAME COLUMN user TO changed_by;
ALTER TABLE ueb RENAME COLUMN korrektur TO changed_at;
ALTER TABLE ueb RENAME TO week_targets;

-- itp_ls -> planned_steps
ALTER TABLE itp_ls RENAME COLUMN spid TO owner;
ALTER TABLE itp_ls RENAME COLUMN wodate TO monday;
ALTER TABLE itp_ls RENAME COLUMN ueb TO exercise;
ALTER TABLE itp_ls RENAME COLUMN lststbem TO steps;
ALTER TABLE itp_ls RENAME COLUMN user TO changed_by;
ALTER TABLE itp_ls RENAME COLUMN korrektur TO changed_at;
ALTER TABLE itp_ls RENAME TO planned_steps;

-- geloescht -> deletions
ALTER TABLE geloescht RENAME COLUMN tabelle TO table_name;
ALTER TABLE geloescht RENAME COLUMN schluessel TO row_key;
ALTER TABLE geloescht RENAME COLUMN korrektur TO deleted_at;
ALTER TABLE geloescht RENAME TO deletions;

-- The deletion log names its tables by the new names too
UPDATE deletions SET table_name = CASE table_name
    WHEN 'sp' THEN 'athletes'
    WHEN 'te' THEN 'sessions'
    WHEN 'te_ueb' THEN 'session_entries'
    WHEN 'wo' THEN 'weeks'
    WHEN 'normen' THEN 'reference_totals'
    WHEN 'spinfo' THEN 'athlete_info'
    WHEN 'wk' THEN 'competitions'
    WHEN 'maz' THEN 'macrocycles'
    WHEN 'maz_sp' THEN 'macrocycle_athletes'
    WHEN 'ueb' THEN 'week_targets'
    WHEN 'itp_ls' THEN 'planned_steps'
    ELSE table_name END;

UPDATE meta SET value = '3' WHERE key = 'schema';
