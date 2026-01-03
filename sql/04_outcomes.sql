-- Step 4: Outcomes and time-to-event variables (index = delirium onset, 30-day follow-up)

ALTER TABLE z_deli_first
ADD COLUMN IF NOT EXISTS death_time TIMESTAMP,
ADD COLUMN IF NOT EXISTS death_30d_post_delirium INT,
ADD COLUMN IF NOT EXISTS death_60d_post_delirium INT,
ADD COLUMN IF NOT EXISTS cox_time_day DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS cox_status INT,
ADD COLUMN IF NOT EXISTS cox_type VARCHAR(50);

UPDATE z_deli_first fd
SET
    death_time = pat.dod,
    death_30d_post_delirium = CASE
        WHEN pat.dod IS NOT NULL
         AND pat.dod <= fd.first_delirium_time + INTERVAL '30 days'
        THEN 1 ELSE 0 END,
    death_60d_post_delirium = CASE
        WHEN pat.dod IS NOT NULL
         AND pat.dod <= fd.first_delirium_time + INTERVAL '60 days'
        THEN 1 ELSE 0 END,
    cox_time_day = EXTRACT(EPOCH FROM (
        LEAST(COALESCE(pat.dod, 'infinity'), fd.first_delirium_time + INTERVAL '30 days')
        - fd.first_delirium_time
    )) / 3600 / 24,
    cox_status = CASE
        WHEN pat.dod IS NOT NULL
         AND pat.dod <= fd.first_delirium_time + INTERVAL '30 days'
        THEN 1 ELSE 0 END,
    cox_type = CASE
        WHEN pat.dod IS NOT NULL
         AND pat.dod <= fd.first_delirium_time + INTERVAL '30 days'
        THEN 'Death' ELSE '30-day-censor' END
FROM mimiciv_hosp.patients pat
WHERE pat.subject_id = (
    SELECT subject_id
    FROM z_base_stay
    WHERE stay_id = fd.stay_id
    LIMIT 1
);
