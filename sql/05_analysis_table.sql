-- Step 5: Analysis-ready delirium-positive cohort table

DROP TABLE IF EXISTS z_final_analysis;

CREATE TABLE z_final_analysis AS
SELECT
    bs.stay_id,
    bs.subject_id,
    bs.hadm_id,
    bs.intime AS icu_admission_time,
    fd.first_delirium_time,
    EXTRACT(EPOCH FROM (fd.first_delirium_time - bs.intime)) / 3600 AS delirium_onset_hour,
    bs.los AS icu_los_days,
    bs.age,
    bs.gender,
    bs.ethnicity,
    fd.death_30d_post_delirium,
    fd.death_60d_post_delirium,
    fd.cox_time_day,
    fd.cox_status,
    fd.cox_type
FROM z_base_stay bs
JOIN z_deli_first fd
  ON bs.stay_id = fd.stay_id
WHERE fd.cam_icu_positive = 1;

CREATE INDEX IF NOT EXISTS idx_z_final_analysis_stay ON z_final_analysis(stay_id);
