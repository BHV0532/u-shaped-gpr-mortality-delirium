-- Step 3: CAM-ICU positivity per assessment time and first positive time per stay

DROP TABLE IF EXISTS z_assess_each;

CREATE TABLE z_assess_each AS
WITH merged AS (
    SELECT
        COALESCE(f1.stay_id, f2.stay_id, f3.stay_id, f4.stay_id)       AS stay_id,
        COALESCE(f1.charttime, f2.charttime, f3.charttime, f4.charttime) AS charttime,
        COALESCE(MAX(f1.feat1), 0) AS feat1,
        COALESCE(MAX(f2.feat2), 0) AS feat2,
        COALESCE(MAX(f3.feat3), 0) AS feat3,
        COALESCE(MAX(f4.feat4), 0) AS feat4
    FROM z_feat1_ms f1
    FULL JOIN z_feat2_inatt f2 USING (stay_id, charttime)
    FULL JOIN z_feat3_dt    f3 USING (stay_id, charttime)
    FULL JOIN z_feat4_loc   f4 USING (stay_id, charttime)
    GROUP BY
        COALESCE(f1.stay_id, f2.stay_id, f3.stay_id, f4.stay_id),
        COALESCE(f1.charttime, f2.charttime, f3.charttime, f4.charttime)
)
SELECT
    stay_id,
    charttime,
    CASE
        WHEN (feat1 + feat2 + feat3 >= 3) OR (feat1 + feat2 + feat4 >= 3) THEN 1
        ELSE 0
    END AS cam_positive
FROM merged;

CREATE INDEX IF NOT EXISTS idx_z_assess_each ON z_assess_each(stay_id, charttime);

DROP TABLE IF EXISTS z_deli_first;

CREATE TABLE z_deli_first AS
SELECT
    stay_id,
    MIN(CASE WHEN cam_positive = 1 THEN charttime END) AS first_delirium_time,
    MAX(cam_positive) AS cam_icu_positive
FROM z_assess_each
GROUP BY stay_id;

CREATE INDEX IF NOT EXISTS idx_z_deli_first ON z_deli_first(stay_id);
