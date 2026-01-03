-- Step 2: CAM-ICU feature tables from chartevents

DROP TABLE IF EXISTS z_feat1_ms;
CREATE TABLE z_feat1_ms AS
SELECT DISTINCT
    bs.stay_id,
    ce.charttime,
    ce.valuenum AS feat1
FROM z_base_stay bs
JOIN chartevents ce
  ON bs.hadm_id = ce.hadm_id
WHERE ce.itemid IN (228337, 228300, 229326)
  AND ce.charttime >= bs.intime
  AND ce.value NOT ILIKE '%Unable to Assess%'
  AND ce.valuenum IS NOT NULL;

DROP TABLE IF EXISTS z_feat2_inatt;
CREATE TABLE z_feat2_inatt AS
SELECT DISTINCT
    bs.stay_id,
    ce.charttime,
    ce.valuenum AS feat2
FROM z_base_stay bs
JOIN chartevents ce
  ON bs.hadm_id = ce.hadm_id
WHERE ce.itemid IN (228336, 228301, 229325)
  AND ce.charttime >= bs.intime
  AND ce.value NOT ILIKE '%Unable to Assess%'
  AND ce.valuenum IS NOT NULL;

DROP TABLE IF EXISTS z_feat3_dt;
CREATE TABLE z_feat3_dt AS
SELECT DISTINCT
    bs.stay_id,
    ce.charttime,
    ce.valuenum AS feat3
FROM z_base_stay bs
JOIN chartevents ce
  ON bs.hadm_id = ce.hadm_id
WHERE ce.itemid IN (228335, 228303, 229324)
  AND ce.charttime >= bs.intime
  AND ce.value NOT ILIKE '%Unable to Assess%'
  AND ce.valuenum IS NOT NULL;

DROP TABLE IF EXISTS z_feat4_loc;
CREATE TABLE z_feat4_loc AS
SELECT DISTINCT
    bs.stay_id,
    ce.charttime,
    ce.valuenum AS feat4
FROM z_base_stay bs
JOIN chartevents ce
  ON bs.hadm_id = ce.hadm_id
WHERE ce.itemid IN (228302, 228334)
  AND ce.charttime >= bs.intime
  AND ce.value NOT ILIKE '%Unable to Assess%'
  AND ce.valuenum IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_z_feat1 ON z_feat1_ms(stay_id, charttime);
CREATE INDEX IF NOT EXISTS idx_z_feat2 ON z_feat2_inatt(stay_id, charttime);
CREATE INDEX IF NOT EXISTS idx_z_feat3 ON z_feat3_dt(stay_id, charttime);
CREATE INDEX IF NOT EXISTS idx_z_feat4 ON z_feat4_loc(stay_id, charttime);
