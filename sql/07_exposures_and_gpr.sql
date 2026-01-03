-- Step 7: ICU exposures and early glucose-potassium ratio (GPR) after delirium onset

-- ----------------------------
-- Vasoactive drugs
-- ----------------------------
DROP TABLE IF EXISTS z_vasoactive_drugs;

CREATE TABLE z_vasoactive_drugs AS
SELECT
    ie.stay_id,
    ie.starttime,
    ie.endtime,
    ie.itemid,
    di.label,
    ie.rate,
    ie.amount,
    CASE
        WHEN di.label ILIKE '%dopamine%' THEN 'Dopamine'
        WHEN di.label ILIKE '%dobutamine%' THEN 'Dobutamine'
        WHEN di.label ILIKE '%epinephrine%' OR di.label ILIKE '%adrenaline%' THEN 'Epinephrine'
        WHEN di.label ILIKE '%norepinephrine%' OR di.label ILIKE '%noradrenaline%' THEN 'Norepinephrine'
        WHEN di.label ILIKE '%phenylephrine%' THEN 'Phenylephrine'
        WHEN di.label ILIKE '%vasopressin%' THEN 'Vasopressin'
        WHEN di.label ILIKE '%milrinone%' THEN 'Milrinone'
        ELSE 'Other Vasoactive'
    END AS drug_class
FROM mimiciv_icu.inputevents ie
JOIN mimiciv_icu.d_items di
  ON ie.itemid = di.itemid
JOIN z_base_stay bs
  ON ie.stay_id = bs.stay_id
WHERE ie.itemid IN (221906, 221662, 221289, 221749, 222315, 221653, 221986)
  AND ie.starttime >= bs.intime
  AND ie.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  );

DROP TABLE IF EXISTS z_vasoactive_summary;

CREATE TABLE z_vasoactive_summary AS
SELECT
    stay_id,
    MAX(CASE WHEN drug_class = 'Norepinephrine' THEN 1 ELSE 0 END) AS norepinephrine,
    MAX(CASE WHEN drug_class = 'Dopamine' THEN 1 ELSE 0 END)        AS dopamine,
    MAX(CASE WHEN drug_class = 'Epinephrine' THEN 1 ELSE 0 END)     AS epinephrine,
    MAX(CASE WHEN drug_class = 'Phenylephrine' THEN 1 ELSE 0 END)   AS phenylephrine,
    MAX(CASE WHEN drug_class = 'Vasopressin' THEN 1 ELSE 0 END)     AS vasopressin,
    MAX(CASE WHEN drug_class = 'Dobutamine' THEN 1 ELSE 0 END)      AS dobutamine,
    MAX(CASE WHEN drug_class = 'Milrinone' THEN 1 ELSE 0 END)       AS milrinone,
    MAX(CASE WHEN drug_class <> 'Other Vasoactive' THEN 1 ELSE 0 END) AS any_vasoactive
FROM z_vasoactive_drugs
GROUP BY stay_id;

-- ----------------------------
-- Antibiotics (keyword-based)
-- ----------------------------
DROP TABLE IF EXISTS z_antibiotics;

CREATE TABLE z_antibiotics AS
SELECT DISTINCT
    bs.stay_id,
    p.starttime,
    p.stoptime,
    p.drug,
    CASE
        WHEN p.drug ILIKE '%vancomycin%' THEN 'Vancomycin'
        WHEN p.drug ILIKE '%piperacillin%' OR p.drug ILIKE '%tazobactam%' THEN 'Piperacillin-Tazobactam'
        WHEN p.drug ILIKE '%meropenem%' THEN 'Meropenem'
        WHEN p.drug ILIKE '%cefepime%' THEN 'Cefepime'
        WHEN p.drug ILIKE '%levofloxacin%' THEN 'Levofloxacin'
        WHEN p.drug ILIKE '%linezolid%' THEN 'Linezolid'
        WHEN p.drug ILIKE '%imipenem%' OR p.drug ILIKE '%cilastatin%' THEN 'Imipenem-Cilastatin'
        WHEN p.drug ILIKE '%daptomycin%' THEN 'Daptomycin'
        WHEN p.drug ILIKE '%ceftriaxone%' THEN 'Ceftriaxone'
        WHEN p.drug ILIKE '%ciprofloxacin%' THEN 'Ciprofloxacin'
        WHEN p.drug ILIKE '%ampicillin%' THEN 'Ampicillin'
        WHEN p.drug ILIKE '%gentamicin%' THEN 'Gentamicin'
        WHEN p.drug ILIKE '%tobramycin%' THEN 'Tobramycin'
        ELSE 'Other Antibiotic'
    END AS antibiotic_class
FROM z_base_stay bs
JOIN mimiciv_hosp.prescriptions p
  ON p.subject_id = bs.subject_id
 AND p.hadm_id   = bs.hadm_id
WHERE p.drug_type NOT IN ('BASE')
  AND p.route NOT IN ('OU','OS','OD','AU','AS','AD','TP')
  AND p.starttime >= bs.intime
  AND p.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  )
  AND (
        p.drug ILIKE '%vancomycin%' OR
        p.drug ILIKE '%piperacillin%' OR p.drug ILIKE '%tazobactam%' OR
        p.drug ILIKE '%meropenem%' OR
        p.drug ILIKE '%cefepime%' OR
        p.drug ILIKE '%levofloxacin%' OR
        p.drug ILIKE '%linezolid%' OR
        p.drug ILIKE '%imipenem%' OR p.drug ILIKE '%cilastatin%' OR
        p.drug ILIKE '%daptomycin%' OR
        p.drug ILIKE '%ceftriaxone%' OR
        p.drug ILIKE '%ciprofloxacin%' OR
        p.drug ILIKE '%ampicillin%' OR
        p.drug ILIKE '%gentamicin%' OR
        p.drug ILIKE '%tobramycin%'
  );

DROP TABLE IF EXISTS z_antibiotics_summary;

CREATE TABLE z_antibiotics_summary AS
SELECT
    stay_id,
    MAX(CASE WHEN antibiotic_class = 'Vancomycin' THEN 1 ELSE 0 END) AS vancomycin,
    MAX(CASE WHEN antibiotic_class = 'Piperacillin-Tazobactam' THEN 1 ELSE 0 END) AS piperacillin_tazobactam,
    MAX(CASE WHEN antibiotic_class = 'Meropenem' THEN 1 ELSE 0 END) AS meropenem,
    MAX(CASE WHEN antibiotic_class = 'Cefepime' THEN 1 ELSE 0 END) AS cefepime,
    MAX(CASE WHEN antibiotic_class = 'Levofloxacin' THEN 1 ELSE 0 END) AS levofloxacin,
    MAX(CASE WHEN antibiotic_class = 'Linezolid' THEN 1 ELSE 0 END) AS linezolid,
    MAX(CASE WHEN antibiotic_class = 'Imipenem-Cilastatin' THEN 1 ELSE 0 END) AS imipenem_cilastatin,
    MAX(CASE WHEN antibiotic_class = 'Daptomycin' THEN 1 ELSE 0 END) AS daptomycin,
    MAX(CASE WHEN antibiotic_class = 'Ceftriaxone' THEN 1 ELSE 0 END) AS ceftriaxone,
    MAX(CASE WHEN antibiotic_class <> 'Other Antibiotic' THEN 1 ELSE 0 END) AS any_antibiotic
FROM z_antibiotics
GROUP BY stay_id;

-- ----------------------------
-- CRRT
-- ----------------------------
DROP TABLE IF EXISTS z_crrt;

CREATE TABLE z_crrt AS
SELECT
    ce.stay_id,
    ce.charttime,
    ce.value AS crrt_mode
FROM z_base_stay bs
JOIN mimiciv_icu.chartevents ce
  ON ce.stay_id = bs.stay_id
WHERE ce.itemid = 227290
  AND ce.charttime >= bs.intime
  AND ce.charttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  );

DROP TABLE IF EXISTS z_crrt_summary;

CREATE TABLE z_crrt_summary AS
SELECT
    stay_id,
    CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS crrt
FROM z_crrt
GROUP BY stay_id;

-- ----------------------------
-- Steroids
-- ----------------------------
DROP TABLE IF EXISTS z_steroids;

CREATE TABLE z_steroids AS
SELECT DISTINCT
    bs.stay_id,
    p.starttime,
    p.stoptime,
    p.drug,
    CASE
        WHEN p.drug ILIKE '%hydrocortisone%' OR p.drug ILIKE '%cortisol%' THEN 'Hydrocortisone'
        WHEN p.drug ILIKE '%methylprednisolone%' THEN 'Methylprednisolone'
        WHEN p.drug ILIKE '%dexamethasone%' THEN 'Dexamethasone'
        WHEN p.drug ILIKE '%prednisone%' THEN 'Prednisone'
        ELSE 'Other Steroid'
    END AS steroid_type
FROM z_base_stay bs
JOIN mimiciv_hosp.prescriptions p
  ON p.subject_id = bs.subject_id
 AND p.hadm_id   = bs.hadm_id
WHERE p.starttime >= bs.intime
  AND p.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  )
  AND (
        p.drug ILIKE '%hydrocortisone%' OR p.drug ILIKE '%cortisol%' OR
        p.drug ILIKE '%methylprednisolone%' OR p.drug ILIKE '%dexamethasone%' OR
        p.drug ILIKE '%prednisone%'
  );

DROP TABLE IF EXISTS z_steroids_summary;

CREATE TABLE z_steroids_summary AS
SELECT
    stay_id,
    MAX(CASE WHEN steroid_type = 'Hydrocortisone' THEN 1 ELSE 0 END) AS hydrocortisone,
    MAX(CASE WHEN steroid_type = 'Methylprednisolone' THEN 1 ELSE 0 END) AS methylprednisolone,
    MAX(CASE WHEN steroid_type = 'Dexamethasone' THEN 1 ELSE 0 END) AS dexamethasone,
    MAX(CASE WHEN steroid_type <> 'Other Steroid' THEN 1 ELSE 0 END) AS any_steroid
FROM z_steroids
GROUP BY stay_id;

-- ----------------------------
-- Benzodiazepines
-- ----------------------------
DROP TABLE IF EXISTS z_benzodiazepines;

CREATE TABLE z_benzodiazepines AS
SELECT DISTINCT
    bs.stay_id,
    p.starttime,
    p.stoptime,
    p.drug,
    CASE
        WHEN p.drug ILIKE '%midazolam%' THEN 'Midazolam'
        WHEN p.drug ILIKE '%lorazepam%' THEN 'Lorazepam'
        WHEN p.drug ILIKE '%diazepam%' THEN 'Diazepam'
        ELSE 'Other Benzodiazepine'
    END AS benzo_type
FROM z_base_stay bs
JOIN mimiciv_hosp.prescriptions p
  ON p.subject_id = bs.subject_id
 AND p.hadm_id   = bs.hadm_id
WHERE p.starttime >= bs.intime
  AND p.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  )
  AND (
        p.drug ILIKE '%midazolam%' OR
        p.drug ILIKE '%lorazepam%' OR
        p.drug ILIKE '%diazepam%'
  );

DROP TABLE IF EXISTS z_benzodiazepines_summary;

CREATE TABLE z_benzodiazepines_summary AS
SELECT
    stay_id,
    MAX(CASE WHEN benzo_type = 'Midazolam' THEN 1 ELSE 0 END) AS midazolam,
    MAX(CASE WHEN benzo_type = 'Lorazepam' THEN 1 ELSE 0 END) AS lorazepam,
    MAX(CASE WHEN benzo_type = 'Diazepam' THEN 1 ELSE 0 END) AS diazepam,
    MAX(CASE WHEN benzo_type <> 'Other Benzodiazepine' THEN 1 ELSE 0 END) AS any_benzodiazepine
FROM z_benzodiazepines
GROUP BY stay_id;

-- ----------------------------
-- Dexmedetomidine
-- ----------------------------
DROP TABLE IF EXISTS z_dexmedetomidine;

CREATE TABLE z_dexmedetomidine AS
SELECT DISTINCT
    bs.stay_id,
    p.starttime,
    p.stoptime,
    p.drug
FROM z_base_stay bs
JOIN mimiciv_hosp.prescriptions p
  ON p.subject_id = bs.subject_id
 AND p.hadm_id   = bs.hadm_id
WHERE (p.drug ILIKE '%dexmedetomidine%' OR p.drug ILIKE '%precedex%')
  AND p.starttime >= bs.intime
  AND p.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  );

DROP TABLE IF EXISTS z_dexmedetomidine_summary;

CREATE TABLE z_dexmedetomidine_summary AS
SELECT
    stay_id,
    CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS dexmedetomidine
FROM z_dexmedetomidine
GROUP BY stay_id;

-- ----------------------------
-- Blood transfusion
-- ----------------------------
DROP TABLE IF EXISTS z_blood_transfusion;

CREATE TABLE z_blood_transfusion AS
SELECT
    ie.stay_id,
    ie.starttime,
    ie.endtime,
    ie.itemid,
    di.label,
    ie.amount,
    CASE
        WHEN di.label ILIKE '%packed red blood cells%' OR di.label ILIKE '%prbc%' OR di.label ILIKE '%rbc%' THEN 'PRBC'
        WHEN di.label ILIKE '%platelets%' THEN 'Platelets'
        WHEN di.label ILIKE '%fresh frozen plasma%' OR di.label ILIKE '%ffp%' THEN 'FFP'
        ELSE 'Other Blood Product'
    END AS blood_product_type
FROM z_base_stay bs
JOIN mimiciv_icu.inputevents ie
  ON ie.stay_id = bs.stay_id
JOIN mimiciv_icu.d_items di
  ON ie.itemid = di.itemid
WHERE ie.itemid IN (225168, 225170, 220950, 225176, 225177, 225171, 225172)
  AND ie.starttime >= bs.intime
  AND ie.starttime <= COALESCE(
        (SELECT first_delirium_time + INTERVAL '30 days' FROM z_deli_first d WHERE d.stay_id = bs.stay_id),
        bs.outtime
  );

DROP TABLE IF EXISTS z_transfusion_summary;

CREATE TABLE z_transfusion_summary AS
SELECT
    stay_id,
    MAX(CASE WHEN blood_product_type = 'PRBC' THEN 1 ELSE 0 END) AS prbc_transfusion,
    MAX(CASE WHEN blood_product_type = 'Platelets' THEN 1 ELSE 0 END) AS platelet_transfusion,
    MAX(CASE WHEN blood_product_type = 'FFP' THEN 1 ELSE 0 END) AS ffp_transfusion,
    MAX(CASE WHEN blood_product_type IN ('PRBC','Platelets','FFP') THEN 1 ELSE 0 END) AS any_blood_transfusion
FROM z_blood_transfusion
GROUP BY stay_id;

-- ----------------------------
-- Early GPR after delirium onset (24h / 48h windows)
-- ----------------------------
DROP TABLE IF EXISTS z_gpr_24h;
CREATE TABLE z_gpr_24h AS
WITH anchor AS (
    SELECT
        fa.stay_id,
        fa.subject_id,
        fa.hadm_id,
        fa.first_delirium_time AS t0
    FROM z_final_analysis fa
),
glucose AS (
    SELECT
        a.stay_id,
        le.valuenum AS glucose_value
    FROM anchor a
    JOIN mimiciv_hosp.labevents le
      ON le.subject_id = a.subject_id
     AND le.hadm_id   = a.hadm_id
    WHERE le.itemid IN (50809, 50906)
      AND le.valuenum IS NOT NULL
      AND le.charttime >= a.t0
      AND le.charttime <= a.t0 + INTERVAL '24 hours'
),
potassium AS (
    SELECT
        a.stay_id,
        le.valuenum AS potassium_value
    FROM anchor a
    JOIN mimiciv_hosp.labevents le
      ON le.subject_id = a.subject_id
     AND le.hadm_id   = a.hadm_id
    WHERE le.itemid IN (50822, 50971)
      AND le.valuenum IS NOT NULL
      AND le.charttime >= a.t0
      AND le.charttime <= a.t0 + INTERVAL '24 hours'
),
glucose_avg AS (
    SELECT stay_id, AVG(glucose_value) AS avg_glucose_24h
    FROM glucose
    GROUP BY stay_id
),
potassium_avg AS (
    SELECT stay_id, AVG(potassium_value) AS avg_potassium_24h
    FROM potassium
    GROUP BY stay_id
)
SELECT
    ga.stay_id,
    ga.avg_glucose_24h,
    pa.avg_potassium_24h,
    ga.avg_glucose_24h / NULLIF(pa.avg_potassium_24h, 0) AS gpr_24h
FROM glucose_avg ga
LEFT JOIN potassium_avg pa USING (stay_id);

DROP TABLE IF EXISTS z_gpr_48h;
CREATE TABLE z_gpr_48h AS
WITH anchor AS (
    SELECT
        fa.stay_id,
        fa.subject_id,
        fa.hadm_id,
        fa.first_delirium_time AS t0
    FROM z_final_analysis fa
),
glucose AS (
    SELECT
        a.stay_id,
        le.valuenum AS glucose_value
    FROM anchor a
    JOIN mimiciv_hosp.labevents le
      ON le.subject_id = a.subject_id
     AND le.hadm_id   = a.hadm_id
    WHERE le.itemid IN (50809, 50906)
      AND le.valuenum IS NOT NULL
      AND le.charttime >= a.t0
      AND le.charttime <= a.t0 + INTERVAL '48 hours'
),
potassium AS (
    SELECT
        a.stay_id,
        le.valuenum AS potassium_value
    FROM anchor a
    JOIN mimiciv_hosp.labevents le
      ON le.subject_id = a.subject_id
     AND le.hadm_id   = a.hadm_id
    WHERE le.itemid IN (50822, 50971)
      AND le.valuenum IS NOT NULL
      AND le.charttime >= a.t0
      AND le.charttime <= a.t0 + INTERVAL '48 hours'
),
glucose_avg AS (
    SELECT stay_id, AVG(glucose_value) AS avg_glucose_48h
    FROM glucose
    GROUP BY stay_id
),
potassium_avg AS (
    SELECT stay_id, AVG(potassium_value) AS avg_potassium_48h
    FROM potassium
    GROUP BY stay_id
)
SELECT
    ga.stay_id,
    ga.avg_glucose_48h,
    pa.avg_potassium_48h,
    ga.avg_glucose_48h / NULLIF(pa.avg_potassium_48h, 0) AS gpr_48h
FROM glucose_avg ga
LEFT JOIN potassium_avg pa USING (stay_id);

-- ----------------------------
-- Final enriched table
-- ----------------------------
DROP TABLE IF EXISTS z_final_analysis_complete;

CREATE TABLE z_final_analysis_complete AS
SELECT
    fa.*,
    COALESCE(vas.norepinephrine, 0) AS norepinephrine,
    COALESCE(vas.dopamine, 0) AS dopamine,
    COALESCE(vas.epinephrine, 0) AS epinephrine,
    COALESCE(vas.phenylephrine, 0) AS phenylephrine,
    COALESCE(vas.vasopressin, 0) AS vasopressin,
    COALESCE(vas.dobutamine, 0) AS dobutamine,
    COALESCE(vas.milrinone, 0) AS milrinone,
    COALESCE(vas.any_vasoactive, 0) AS any_vasoactive,

    COALESCE(abx.vancomycin, 0) AS vancomycin,
    COALESCE(abx.piperacillin_tazobactam, 0) AS piperacillin_tazobactam,
    COALESCE(abx.meropenem, 0) AS meropenem,
    COALESCE(abx.cefepime, 0) AS cefepime,
    COALESCE(abx.levofloxacin, 0) AS levofloxacin,
    COALESCE(abx.linezolid, 0) AS linezolid,
    COALESCE(abx.imipenem_cilastatin, 0) AS imipenem_cilastatin,
    COALESCE(abx.daptomycin, 0) AS daptomycin,
    COALESCE(abx.ceftriaxone, 0) AS ceftriaxone,
    COALESCE(abx.any_antibiotic, 0) AS any_antibiotic,

    COALESCE(crrt.crrt, 0) AS crrt,

    COALESCE(st.any_steroid, 0) AS any_steroid,
    COALESCE(st.hydrocortisone, 0) AS hydrocortisone,
    COALESCE(st.methylprednisolone, 0) AS methylprednisolone,
    COALESCE(st.dexamethasone, 0) AS dexamethasone,

    COALESCE(ben.any_benzodiazepine, 0) AS any_benzodiazepine,
    COALESCE(ben.midazolam, 0) AS midazolam,
    COALESCE(ben.lorazepam, 0) AS lorazepam,
    COALESCE(ben.diazepam, 0) AS diazepam,

    COALESCE(dex.dexmedetomidine, 0) AS dexmedetomidine,

    COALESCE(trans.any_blood_transfusion, 0) AS any_blood_transfusion,
    COALESCE(trans.prbc_transfusion, 0) AS prbc_transfusion,
    COALESCE(trans.platelet_transfusion, 0) AS platelet_transfusion,
    COALESCE(trans.ffp_transfusion, 0) AS ffp_transfusion,

    gpr24.gpr_24h,
    gpr24.avg_glucose_24h,
    gpr24.avg_potassium_24h,

    gpr48.gpr_48h,
    gpr48.avg_glucose_48h,
    gpr48.avg_potassium_48h
FROM z_final_analysis fa
LEFT JOIN z_vasoactive_summary       vas   ON fa.stay_id = vas.stay_id
LEFT JOIN z_antibiotics_summary      abx   ON fa.stay_id = abx.stay_id
LEFT JOIN z_crrt_summary             crrt  ON fa.stay_id = crrt.stay_id
LEFT JOIN z_steroids_summary         st    ON fa.stay_id = st.stay_id
LEFT JOIN z_benzodiazepines_summary  ben   ON fa.stay_id = ben.stay_id
LEFT JOIN z_dexmedetomidine_summary  dex   ON fa.stay_id = dex.stay_id
LEFT JOIN z_transfusion_summary      trans ON fa.stay_id = trans.stay_id
LEFT JOIN z_gpr_24h                  gpr24 ON fa.stay_id = gpr24.stay_id
LEFT JOIN z_gpr_48h                  gpr48 ON fa.stay_id = gpr48.stay_id;
