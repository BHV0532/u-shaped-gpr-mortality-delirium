-- Step 1: Adult first ICU stay cohort with ICU LOS >= 24 hours

DROP TABLE IF EXISTS z_base_stay;

CREATE TABLE z_base_stay AS
WITH first_icu AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        intime,
        outtime,
        los,
        ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY intime) AS icu_order
    FROM icustays
)
SELECT
    fi.subject_id,
    fi.hadm_id,
    fi.stay_id,
    fi.intime,
    fi.outtime,
    fi.los,
    pat.anchor_age AS age,
    pat.gender,
    adm.race AS ethnicity
FROM first_icu fi
JOIN patients   pat ON fi.subject_id = pat.subject_id
JOIN admissions adm ON fi.hadm_id   = adm.hadm_id
WHERE fi.icu_order = 1
  AND fi.los >= 1
  AND pat.anchor_age >= 18;

CREATE INDEX IF NOT EXISTS idx_z_base_stay_stay_id ON z_base_stay(stay_id);
CREATE INDEX IF NOT EXISTS idx_z_base_stay_hadm_id ON z_base_stay(hadm_id);
