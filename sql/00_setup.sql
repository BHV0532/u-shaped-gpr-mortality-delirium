-- MIMIC-IV: Delirium cohort + early GPR after delirium onset
-- Setup schema search_path and performance indexes

SET search_path TO mimiciv_derived, mimiciv_icu, mimiciv_hosp, public;

-- Optional indexes for faster execution (safe to re-run)
CREATE INDEX IF NOT EXISTS idx_inputevents_stay_id     ON mimiciv_icu.inputevents(stay_id);
CREATE INDEX IF NOT EXISTS idx_inputevents_itemid      ON mimiciv_icu.inputevents(itemid);
CREATE INDEX IF NOT EXISTS idx_inputevents_starttime   ON mimiciv_icu.inputevents(starttime);
CREATE INDEX IF NOT EXISTS idx_d_items_itemid          ON mimiciv_icu.d_items(itemid);

CREATE INDEX IF NOT EXISTS idx_prescriptions_starttime ON mimiciv_hosp.prescriptions(starttime);
CREATE INDEX IF NOT EXISTS idx_chartevents_stay_time   ON mimiciv_icu.chartevents(stay_id, charttime);
CREATE INDEX IF NOT EXISTS idx_labevents_key_time      ON mimiciv_hosp.labevents(subject_id, hadm_id, charttime);
